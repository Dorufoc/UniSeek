package com.uniseek.upload.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.upload.service.UploadService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

/**
 * 文件上传控制器
 *
 * <p>提供图片和通用文件的上传功能。</p>
 */
@RestController
@RequestMapping("/api/upload")
public class UploadController {

    private static final Logger log = LoggerFactory.getLogger(UploadController.class);

    @Autowired
    private UploadService uploadService;

    /**
     * 上传图片
     * POST /api/upload/image（需要鉴权）
     *
     * @param file 图片文件，支持 jpg/png/webp，最大 5MB
     * @return 图片访问 URL
     */
    @PostMapping("/image")
    public ApiResult<Map<String, String>> uploadImage(@RequestParam("file") MultipartFile file) {
        String url = uploadService.uploadImage(file);
        Map<String, String> data = new HashMap<>(1);
        data.put("url", url);
        log.info("图片上传成功: {}", url);
        return ApiResult.success("上传成功", data);
    }

    /**
     * 上传文件
     * POST /api/upload/file（需要鉴权）
     *
     * @param file 通用文件，支持 pdf/doc/docx，最大 10MB
     * @return 文件访问 URL
     */
    @PostMapping("/file")
    public ApiResult<Map<String, String>> uploadFile(@RequestParam("file") MultipartFile file) {
        String url = uploadService.uploadFile(file);
        Map<String, String> data = new HashMap<>(1);
        data.put("url", url);
        log.info("文件上传成功: {}", url);
        return ApiResult.success("上传成功", data);
    }
}
