package com.uniseek.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.common.util.UserContext;
import com.uniseek.dto.ResumeRequest;
import com.uniseek.entity.Resume;
import com.uniseek.operationlog.annotation.OperationLog;
import com.uniseek.service.ResumeService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.uniseek.upload.service.UploadService;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 简历控制器
 */
@RestController
@RequestMapping("/api/resume")
public class ResumeController {

    private static final Logger log = LoggerFactory.getLogger(ResumeController.class);

    @Autowired
    private ResumeService resumeService;

    @Autowired
    private UploadService uploadService;

    /**
     * 获取我的简历
     * GET /api/resume（需要鉴权）
     */
    @GetMapping
    public ApiResult<Resume> getMyResume() {
        Long userId = UserContext.getUserId();
        Resume resume = resumeService.getUserResume(userId);
        return ApiResult.success(resume);
    }

    /**
     * 创建/更新简历
     * PUT /api/resume（需要鉴权）
     * 注意：请求体中的 realName 字段将被服务端忽略
     */
    @OperationLog(operationType = "SAVE_RESUME", targetType = "RESUME")
    @PutMapping
    public ApiResult<Void> saveOrUpdateResume(@RequestBody ResumeRequest request) {
        Long userId = UserContext.getUserId();
        resumeService.saveOrUpdateResume(userId, request);
        return ApiResult.success("保存成功", null);
    }

    /**
     * 发布简历到人才市场
     * PATCH /api/resume/publish
     */
    @OperationLog(operationType = "PUBLISH_RESUME", targetType = "RESUME")
    @PatchMapping("/publish")
    public ApiResult<Void> publishResume() {
        Long userId = UserContext.getUserId();
        resumeService.publishResume(userId);
        return ApiResult.success("发布成功", null);
    }

    /**
     * 从人才市场下架简历
     * PATCH /api/resume/unpublish
     */
    @OperationLog(operationType = "UNPUBLISH_RESUME", targetType = "RESUME")
    @PatchMapping("/unpublish")
    public ApiResult<Void> unpublishResume() {
        Long userId = UserContext.getUserId();
        resumeService.unpublishResume(userId);
        return ApiResult.success("已下架", null);
    }

    /**
     * 分页搜索人才市场已发布的简历
     * GET /api/resume/search
     *
     * @param keyword  搜索关键词
     * @param page     页码（默认 1）
     * @param pageSize 每页条数（默认 20）
     */
    @GetMapping("/search")
    public ApiResult<PageResult<Resume>> searchPublishedResumes(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        PageResult<Resume> result = resumeService.searchPublishedResumes(keyword, page, pageSize);
        return ApiResult.success(result);
    }

    /**
     * 查看指定用户的已发布简历（供招聘者查看人才详情）
     * GET /api/resume/user/{userId}
     */
    @GetMapping("/user/{userId}")
    public ApiResult<Resume> getPublishedResume(@PathVariable Long userId) {
        Resume resume = resumeService.getUserResume(userId);
        if (resume == null || resume.getIsPublished() != 1) {
            throw new BusinessException("该用户未发布简历");
        }
        return ApiResult.success(resume);
    }

    /**
     * 上传附件简历
     * POST /api/resume/upload-attachment（需要鉴权）
     *
     * @param file 附件简历文件（支持 pdf、doc、docx，最大 10MB）
     * @return 文件访问 URL
     */
    @OperationLog(operationType = "UPLOAD_RESUME", targetType = "RESUME")
    @PostMapping("/upload-attachment")
    public ApiResult<Map<String, String>> uploadAttachment(@RequestParam("file") MultipartFile file) {
        String url = uploadService.uploadFile(file);
        Map<String, String> result = new HashMap<>();
        result.put("url", url);
        return ApiResult.success("上传成功", result);
    }
}