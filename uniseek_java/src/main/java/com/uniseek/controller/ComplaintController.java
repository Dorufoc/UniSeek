package com.uniseek.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.common.util.UserContext;
import com.uniseek.dto.ComplaintRequest;
import com.uniseek.entity.Complaint;
import com.uniseek.service.ComplaintService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 投诉控制器
 */
@RestController
@RequestMapping("/api/complaints")
public class ComplaintController {

    private static final Logger log = LoggerFactory.getLogger(ComplaintController.class);

    @Autowired
    private ComplaintService complaintService;

    /**
     * 提交投诉
     * POST /api/complaints（需要鉴权）
     */
    @PostMapping
    public ApiResult<Map<String, Object>> submit(@RequestBody ComplaintRequest request) {
        Long userId = UserContext.getUserId();
        Complaint complaint = complaintService.submit(userId, request);

        Map<String, Object> data = new HashMap<>();
        data.put("id", complaint.getId());
        data.put("status", complaint.getStatus());
        data.put("createTime", complaint.getCreateTime());

        return ApiResult.success("投诉提交成功", data);
    }
}
