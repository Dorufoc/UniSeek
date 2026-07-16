package com.uniseek.service;

import com.uniseek.common.PageResult;
import com.uniseek.dto.ResumeRequest;
import com.uniseek.entity.Resume;

/**
 * 简历服务接口
 */
public interface ResumeService {

    /**
     * 获取用户的简历信息（含 realName，从 real_name_auth 表 JOIN 查询）
     *
     * @param userId 用户 ID
     * @return 简历实体（含 realName 字段），不存在时返回 null
     */
    Resume getUserResume(Long userId);

    /**
     * 创建或更新简历信息
     * 若请求体包含 realName 字段，服务端忽略该字段
     *
     * @param userId  用户 ID
     * @param request 简历请求 DTO
     */
    void saveOrUpdateResume(Long userId, ResumeRequest request);

    /**
     * 发布简历到人才市场
     */
    void publishResume(Long userId);

    /**
     * 从人才市场下架简历
     */
    void unpublishResume(Long userId);

    /**
     * 分页搜索已发布到人才市场的简历
     *
     * @param keyword  关键词（匹配姓名和技能标签）
     * @param page     页码
     * @param pageSize 每页条数
     * @return 分页结果
     */
    PageResult<Resume> searchPublishedResumes(String keyword, int page, int pageSize);
}