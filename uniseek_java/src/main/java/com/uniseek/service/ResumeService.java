package com.uniseek.service;

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
}