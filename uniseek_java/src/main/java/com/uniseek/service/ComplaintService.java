package com.uniseek.service;

import com.uniseek.dto.ComplaintRequest;
import com.uniseek.entity.Complaint;

/**
 * 投诉服务接口
 */
public interface ComplaintService {

    /**
     * 提交投诉
     *
     * @param userId  投诉人 ID
     * @param request 投诉请求
     * @return 创建的投诉记录
     */
    Complaint submit(Long userId, ComplaintRequest request);
}
