/*
 * Copyright (c) 2016 Bilibili
 * copyright (c) 2016 Zhang Rui <bbcallen@gmail.com>
 *
 * This file is part of ijkPlayer.
 *
 * ijkPlayer is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * ijkPlayer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with ijkPlayer; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "internal.h"
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import <CoreVideo/CoreVideo.h>
#include "ijksdl_vout_overlay_videotoolbox.h"
#import <AppKit/AppKit.h>
#import <CoreImage/CoreImage.h>

typedef struct IJK_GLES2_Renderer_Opaque
{
    CVOpenGLTextureCacheRef cv_texture_cache;
    CVOpenGLTextureRef      cv_texture[2];

    CFTypeRef                 color_attachments;
    
    UInt8 * texture_data_y;
    UInt8 * texture_data_uv;
    size_t texture_datasize_y;
    size_t texture_datasize_uv;
    
    
} IJK_GLES2_Renderer_Opaque;

static GLboolean yuv420sp_vtb_use(IJK_GLES2_Renderer *renderer)
{
    ALOGI("use render yuv420sp_vtb\n");
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    glUseProgram(renderer->program);            IJK_GLES2_checkError_TRACE("glUseProgram");

    if (0 == renderer->plane_textures[0])
        glGenTextures(2, renderer->plane_textures);
    
    for (int i = 0; i < 2; ++i) {
        glUniform1i(renderer->us2_sampler[i], i);
    }

    glUniformMatrix3fv(renderer->um3_color_conversion, 1, GL_FALSE, IJK_GLES2_getColorMatrix_bt709());
    
    return GL_TRUE;
}

static GLvoid yuv420sp_vtb_clean_textures(IJK_GLES2_Renderer *renderer)
{
    if (!renderer || !renderer->opaque)
        return;

    IJK_GLES2_Renderer_Opaque *opaque = renderer->opaque;
    


    for (int i = 0; i < 2; ++i) {
        if (opaque->cv_texture[i]) {
            CFRelease(opaque->cv_texture[i]);
            opaque->cv_texture[i] = nil;
        }
    }

    // Periodic texture cache flush every frame
    if (opaque->cv_texture_cache)
        CVOpenGLTextureCacheFlush(opaque->cv_texture_cache, 0);
    
    
}

static GLsizei yuv420sp_vtb_getBufferWidth(IJK_GLES2_Renderer *renderer, SDL_VoutOverlay *overlay)
{
    if (!overlay)
        return 0;

    return overlay->pitches[0] / 1;
}

static int SGYUVChannelFilterNeedSize(int linesize, int width, int height, int channel_count)
{
    width = MIN(linesize, width);
    return width * height * channel_count;
}

static void SGYUVChannelFilter(UInt8 * src, int linesize, int width, int height, UInt8 * dst, size_t dstsize, int channel_count)
{
    width = MIN(linesize, width);
    UInt8 * temp = dst;
    memset(dst, 0, dstsize);
    for (int i = 0; i < height; i++) {
        memcpy(temp, src, width * channel_count);
        temp += (width * channel_count);
        src += linesize;
    }
}

static void createImage(CVPixelBufferRef pixel_buffer){
    
    static int i = 0;
    i ++ ;
    if(i < 100){
        return;
    }
    return;
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixel_buffer];
    CIContext *cictx = [CIContext contextWithOptions:nil];
    CGImageRef cgimage = [cictx createCGImage:ciImage fromRect:ciImage.extent];
    
    NSImage *newImage = nil;
    NSSize size = NSMakeSize(CGImageGetWidth(cgimage), CGImageGetHeight(cgimage));
    
    newImage = [[NSImage alloc]initWithCGImage:cgimage size:size];
    
    NSData *dataImage = [newImage TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:dataImage];
    
    [imageRep setSize:size];
    NSDictionary *imageProps = nil;
    NSNumber *quality = [NSNumber numberWithFloat:1.f];
    imageProps = [NSDictionary dictionaryWithObject:quality forKey:NSImageCompressionFactor];
    NSData *imageData = [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:imageProps];
    [imageData writeToFile:@"/Users/mini/Desktop/ts.png" atomically:YES];
    
}

static GLboolean yuv420sp_vtb_uploadTexture(IJK_GLES2_Renderer *renderer, SDL_VoutOverlay *overlay)
{
    if (!renderer || !renderer->opaque || !overlay)
        return GL_FALSE;

    if (!overlay->is_private)
        return GL_FALSE;

    switch (overlay->format) {
        case SDL_FCC__VTB:
            break;
        default:
            ALOGE("[yuv420sp_vtb] unexpected format %x\n", overlay->format);
            return GL_FALSE;
    }

    IJK_GLES2_Renderer_Opaque *opaque = renderer->opaque;
    if (!opaque->cv_texture_cache) {
        ALOGE("nil textureCache\n");
        return GL_FALSE;
    }

    CVPixelBufferRef pixel_buffer = SDL_VoutOverlayVideoToolBox_GetCVPixelBufferRef(overlay);
    if (!pixel_buffer) {
        ALOGE("nil pixelBuffer in overlay\n");
        return GL_FALSE;
    }

    CFTypeRef color_attachments = CVBufferGetAttachment(pixel_buffer, kCVImageBufferYCbCrMatrixKey, NULL);
    if (color_attachments != opaque->color_attachments) {
        if (color_attachments == nil) {
            glUniformMatrix3fv(renderer->um3_color_conversion, 1, GL_FALSE, IJK_GLES2_getColorMatrix_bt709());
        } else if (opaque->color_attachments != nil &&
                   CFStringCompare(color_attachments, opaque->color_attachments, 0) == kCFCompareEqualTo) {
            // remain prvious color attachment
        } else if (CFStringCompare(color_attachments, kCVImageBufferYCbCrMatrix_ITU_R_709_2, 0) == kCFCompareEqualTo) {
            glUniformMatrix3fv(renderer->um3_color_conversion, 1, GL_FALSE, IJK_GLES2_getColorMatrix_bt709());
        } else if (CFStringCompare(color_attachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo) {
            glUniformMatrix3fv(renderer->um3_color_conversion, 1, GL_FALSE, IJK_GLES2_getColorMatrix_bt601());
        } else {
            glUniformMatrix3fv(renderer->um3_color_conversion, 1, GL_FALSE, IJK_GLES2_getColorMatrix_bt709());
        }

        if (opaque->color_attachments != nil) {
            CFRelease(opaque->color_attachments);
            opaque->color_attachments = nil;
        }
        if (color_attachments != nil) {
            opaque->color_attachments = CFRetain(color_attachments);
        }
    }
    
    createImage(pixel_buffer);

    yuv420sp_vtb_clean_textures(renderer);
    
    CVPixelBufferLockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
    
    void * data_y = CVPixelBufferGetBaseAddressOfPlane(pixel_buffer, 0);
    int linesize_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixel_buffer, 0);
    int width_y = (int)CVPixelBufferGetWidthOfPlane(pixel_buffer, 0);
    int height_y = (int)CVPixelBufferGetHeightOfPlane(pixel_buffer, 0);
    
    
    void * data_uv = CVPixelBufferGetBaseAddressOfPlane(pixel_buffer, 1);
    int linesize_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(pixel_buffer, 1);
    int width_uv = (int)CVPixelBufferGetWidthOfPlane(pixel_buffer, 1);
    int height_uv = (int)CVPixelBufferGetHeightOfPlane(pixel_buffer, 1);
    

    
    
    
    size_t size_y = SGYUVChannelFilterNeedSize(linesize_y, width_y, height_y, 1);
    if (renderer->opaque->texture_datasize_y < size_y) {
        if (renderer->opaque->texture_datasize_y > 0 && renderer->opaque->texture_data_y != NULL) {
            free(renderer->opaque->texture_data_y);
        }
        renderer->opaque->texture_datasize_y = size_y;
        renderer->opaque->texture_data_y = malloc(renderer->opaque->texture_datasize_y);
    }
    size_t size_uv = SGYUVChannelFilterNeedSize(linesize_uv, width_uv, height_uv, 2);
    if (renderer->opaque->texture_datasize_uv < size_uv) {
        if (renderer->opaque->texture_datasize_uv > 0 && renderer->opaque->texture_data_uv != NULL) {
            free(renderer->opaque->texture_data_uv);
        }
        renderer->opaque->texture_datasize_uv = size_uv;
        renderer->opaque->texture_data_uv = malloc(renderer->opaque->texture_datasize_uv);
    }
    
    SGYUVChannelFilter(data_y, linesize_y, width_y, height_y, renderer->opaque->texture_data_y, renderer->opaque->texture_datasize_y, 1);
    SGYUVChannelFilter(data_uv, linesize_uv, width_uv, height_uv, renderer->opaque->texture_data_uv, renderer->opaque->texture_datasize_uv, 2);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, renderer->plane_textures[0]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, width_y, height_y, 0, GL_RED, GL_UNSIGNED_BYTE, renderer->opaque->texture_data_y);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, renderer->plane_textures[1]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RG, width_uv, height_uv, 0, GL_RG, GL_UNSIGNED_BYTE, renderer->opaque->texture_data_uv);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    
    CVPixelBufferUnlockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
//    NSDictionary *destinationImageBufferAttributes =  @{
//                                                        (id) kCVPixelBufferOpenGLCompatibilityKey : @(YES),
//                                                        (id) kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary],
//                                                        (id) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8Planar)
//                                                        };

//    GLsizei frame_width  = (GLsizei)CVPixelBufferGetWidth(pixel_buffer);
//    GLsizei frame_height = (GLsizei)CVPixelBufferGetHeight(pixel_buffer);
//    CVReturn result;
//    glActiveTexture(GL_TEXTURE0);
//    result = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, opaque->cv_texture_cache, pixel_buffer, NULL, &opaque->cv_texture[0]);
//
//    glBindTexture(CVOpenGLTextureGetTarget(opaque->cv_texture[0]), CVOpenGLTextureGetName(opaque->cv_texture[0]));
//    
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//
//    glActiveTexture(GL_TEXTURE1);
//    result = CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, opaque->cv_texture_cache, pixel_buffer, NULL, &opaque->cv_texture[1]);
//    
//    
//    glBindTexture(CVOpenGLTextureGetTarget(opaque->cv_texture[1]), CVOpenGLTextureGetName(opaque->cv_texture[1]));
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);


    return GL_TRUE;
}

static GLvoid yuv420sp_vtb_destroy(IJK_GLES2_Renderer *renderer)
{
    if (!renderer || !renderer->opaque)
        return;

    yuv420sp_vtb_clean_textures(renderer);
    
    if (renderer->opaque->texture_data_y != NULL) {
        free(renderer->opaque->texture_data_y);
    }
    if (renderer->opaque->texture_data_uv != NULL) {
        free(renderer->opaque->texture_data_uv);
    }
    renderer->opaque->texture_data_y = NULL;
    renderer->opaque->texture_data_uv = NULL;
    renderer->opaque->texture_datasize_y = 0;
    renderer->opaque->texture_datasize_uv = 0;

    IJK_GLES2_Renderer_Opaque *opaque = renderer->opaque;
    if (opaque->cv_texture_cache) {
        CFRelease(opaque->cv_texture_cache);
        opaque->cv_texture_cache = nil;
    }

    if (opaque->color_attachments != nil) {
        CFRelease(opaque->color_attachments);
        opaque->color_attachments = nil;
    }
    free(renderer->opaque);
    renderer->opaque = nil;
}

IJK_GLES2_Renderer *IJK_GLES2_Renderer_create_yuv420sp_vtb(SDL_VoutOverlay *overlay)
{
    CVReturn err = 0;
    NSOpenGLContext *context = (__bridge NSOpenGLContext *)(overlay->usr_data);
    //EAGLContext *context = [EAGLContext currentContext];
    

    if (!overlay) {
        ALOGW("invalid overlay, fall back to yuv420sp renderer\n");
        return IJK_GLES2_Renderer_create_yuv420sp();
    }

    if (!overlay) {
        ALOGW("non-private overlay, fall back to yuv420sp renderer\n");
        return IJK_GLES2_Renderer_create_yuv420sp();
    }

    if (!context) {
        ALOGW("nil EAGLContext, fall back to yuv420sp renderer\n");
        return IJK_GLES2_Renderer_create_yuv420sp();
    }

    ALOGI("create render yuv420sp_vtb\n");
    IJK_GLES2_Renderer *renderer = IJK_GLES2_Renderer_create_base(IJK_GLES2_getFragmentShader_yuv420sp());
    if (!renderer)
        goto fail;

    renderer->us2_sampler[0] = glGetUniformLocation(renderer->program, "us2_SamplerX"); IJK_GLES2_checkError_TRACE("glGetUniformLocation(us2_SamplerX)");
    renderer->us2_sampler[1] = glGetUniformLocation(renderer->program, "us2_SamplerY"); IJK_GLES2_checkError_TRACE("glGetUniformLocation(us2_SamplerY)");

    renderer->um3_color_conversion = glGetUniformLocation(renderer->program, "um3_ColorConversion"); IJK_GLES2_checkError_TRACE("glGetUniformLocation(um3_ColorConversionMatrix)");

    renderer->func_use            = yuv420sp_vtb_use;
    renderer->func_getBufferWidth = yuv420sp_vtb_getBufferWidth;
    renderer->func_uploadTexture  = yuv420sp_vtb_uploadTexture;
    renderer->func_destroy        = yuv420sp_vtb_destroy;

    renderer->opaque = calloc(1, sizeof(IJK_GLES2_Renderer_Opaque));
    if (!renderer->opaque)
        goto fail;

    err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, NULL, context.CGLContextObj, context.pixelFormat.CGLPixelFormatObj, NULL, &renderer->opaque->cv_texture_cache);

    if (err || renderer->opaque->cv_texture_cache == nil) {
        ALOGE("Error at CVOpenGLESTextureCacheCreate %d\n", err);
        goto fail;
    }

    renderer->opaque->color_attachments = CFRetain(kCVImageBufferYCbCrMatrix_ITU_R_709_2);
    
    return renderer;
fail:
    IJK_GLES2_Renderer_free(renderer);
    return NULL;
}
