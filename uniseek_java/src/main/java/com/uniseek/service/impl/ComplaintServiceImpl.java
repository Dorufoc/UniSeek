package com.uniseek.service.impl;

import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.ComplaintMapper;
import com.uniseek.dto.ComplaintRequest;
import com.uniseek.entity.Complaint;
import com.uniseek.service.ComplaintService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 投诉服务实现
 */
@Service
public class ComplaintServiceImpl implements ComplaintService {

    @Autowired
    private ComplaintMapper complaintMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Complaint submit(Long userId, ComplaintRequest request) {
        // 校验内容长度（1~500 字）
        String content = request.getContent();
        if (content == null || content.trim().isEmpty()) {
            throw new BusinessException("投诉内容不能为空");
        }
        if (content.trim().length() > 500) {
            throw new BusinessException("投诉内容不能超过500字");
        }

        // 校验必填参数
        if (request.getTargetType() == null) {
            throw new BusinessException("被投诉对象类型不能为空");
        }
        // 校验投诉对象类型范围（只允许 1-企业, 2-用户）
        if (request.getTargetType() < 1 || request.getTargetType() > 2) {
            throw new BusinessException("投诉对象类型不合法");
        }
        if (request.getTargetId() == null) {
            throw new BusinessException("被投诉对象 ID 不能为空");
        }
        if (request.getType() == null) {
            throw new BusinessException("投诉类型不能为空");
        }

        // 构建投诉实体
        Complaint complaint = new Complaint();
        complaint.setComplainantId(userId);
        complaint.setTargetType(request.getTargetType());
        complaint.setTargetId(request.getTargetId());
        complaint.setType(request.getType());
        complaint.setContent(content.trim());
        complaint.setStatus(0); // 默认待处理
        complaint.setCreateTime(LocalDateTime.now());
        complaint.setUpdateTime(LocalDateTime.now());

        complaintMapper.insert(complaint);
        return complaint;
    }
}
