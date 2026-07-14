package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.common.util.UserContext;
import com.uniseek.dao.*;
import com.uniseek.dto.ApplyRequest;
import com.uniseek.dto.CompleteRequest;
import com.uniseek.dto.UpdateStatusRequest;
import com.uniseek.entity.*;
import com.uniseek.constant.OperationType;
import com.uniseek.entity.OperationLog;
import com.uniseek.service.ApplicationService;
import com.uniseek.service.ApplicationStatusMachine;
import com.uniseek.service.NotificationService;
import com.uniseek.service.OperationLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 投递申请服务实现
 */
@Service
public class ApplicationServiceImpl implements ApplicationService {

    @Autowired
    private TaskApplicationMapper taskApplicationMapper;

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private ResumeMapper resumeMapper;

    @Autowired
    private RealNameAuthMapper realNameAuthMapper;

    @Autowired
    private EnterpriseMapper enterpriseMapper;

    @Autowired
    private ChatSessionMapper chatSessionMapper;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private OperationLogService operationLogService;

    @Autowired
    private ApplicationStatusMachine statusMachine;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public TaskApplication apply(ApplyRequest request) {
        // 1. 获取当前求职者 ID
        Long applicantId = UserContext.getUserId();

        // 2. 校验实名认证
        RealNameAuth realNameAuth = realNameAuthMapper.selectOne(
                new LambdaQueryWrapper<RealNameAuth>()
                        .eq(RealNameAuth::getUserId, applicantId)
                        .eq(RealNameAuth::getStatus, 1));
        if (realNameAuth == null) {
            throw new BusinessException("请先完成实名认证后再投递职位");
        }

        // 3. 校验简历存在
        Resume resume = resumeMapper.selectOne(
                new LambdaQueryWrapper<Resume>()
                        .eq(Resume::getUserId, applicantId));
        if (resume == null) {
            throw new BusinessException("请先创建简历后再投递职位");
        }

        // 4. 校验职位可投递
        Task task = taskMapper.selectById(request.getTaskId());
        if (task == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "职位不存在");
        }
        if (task.getStatus() != 1) {
            throw new BusinessException("当前职位不在招聘中");
        }
        if (task.getDeadline() != null && task.getDeadline().isBefore(LocalDateTime.now())) {
            throw new BusinessException("该职位已截止报名");
        }
        if (task.getRemainingQuota() == null || task.getRemainingQuota() <= 0) {
            throw new BusinessException("该职位报名名额已满");
        }

        // 5. 校验不重复投递
        TaskApplication existing = taskApplicationMapper.selectOne(
                new LambdaQueryWrapper<TaskApplication>()
                        .eq(TaskApplication::getTaskId, request.getTaskId())
                        .eq(TaskApplication::getApplicantId, applicantId));
        if (existing != null) {
            throw new BusinessException(ApiResult.CONFLICT, "您已投递过该职位，请勿重复投递");
        }

        // 6. 生成简历快照：Resume 对象序列化为 JSON 字符串
        String resumeSnapshot;
        try {
            resumeSnapshot = objectMapper.writeValueAsString(resume);
        } catch (Exception e) {
            throw new BusinessException("简历快照生成失败");
        }

        // 7. 插入投递记录（status = 0 已投递）
        TaskApplication application = new TaskApplication();
        application.setTaskId(request.getTaskId());
        application.setApplicantId(applicantId);
        application.setResumeSnapshot(resumeSnapshot);
        application.setAttachmentUrl(resume.getAttachmentUrl());
        application.setStatus(0);
        application.setVersion(1);
        application.setCreateTime(LocalDateTime.now());
        application.setUpdateTime(LocalDateTime.now());
        taskApplicationMapper.insert(application);

        // 8. 创建聊天会话
        Enterprise enterprise = enterpriseMapper.selectById(task.getEnterpriseId());
        if (enterprise != null) {
            ChatSession chatSession = new ChatSession();
            chatSession.setEmployerId(enterprise.getUserId());
            chatSession.setSeekerId(applicantId);
            chatSession.setTaskApplicationId(application.getId());
            chatSession.setCreateTime(LocalDateTime.now());
            chatSession.setUpdateTime(LocalDateTime.now());
            chatSessionMapper.insert(chatSession);
        }

        // 9. 创建通知给 HR
        if (enterprise != null) {
            notificationService.sendNotification(
                    enterprise.getUserId(),   // 接收者 = HR 用户 ID
                    applicantId,              // 发送者 = 求职者 ID
                    "新投递",
                    "您收到一份新的投递申请，请及时查看",
                    0,                        // 类型 0：系统通知
                    application.getId()       // 业务关联 ID
            );
        }

        // 10. 返回投递记录
        return application;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long id, UpdateStatusRequest request) {
        Long userId = UserContext.getUserId();
        Integer userRole = UserContext.getRole();

        // 1. 查询投递记录及关联职位
        TaskApplication application = taskApplicationMapper.selectById(id);
        if (application == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "投递记录不存在");
        }

        Task task = taskMapper.selectById(application.getTaskId());
        if (task == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "关联职位不存在");
        }

        // 2. 校验当前用户是该职位所属企业的 HR（role == 1）
        if (userRole != 1) {
            throw new BusinessException(ApiResult.FORBIDDEN, "仅 HR 可以处理投递");
        }
        Enterprise enterprise = enterpriseMapper.selectById(task.getEnterpriseId());
        if (enterprise == null || !enterprise.getUserId().equals(userId)) {
            throw new BusinessException(ApiResult.FORBIDDEN, "您无权处理该职位的投递");
        }

        // 3. 状态机校验
        Integer currentStatus = application.getStatus();
        Integer newStatus = request.getStatus();
        statusMachine.validateTransition(currentStatus, newStatus);

        // 4. 业务字段校验
        if (newStatus == 1) {
            if (request.getInterviewTime() == null) {
                throw new BusinessException("请选择面试时间");
            }
            if (!StringUtils.hasText(request.getInterviewLocation())) {
                throw new BusinessException("请填写面试地点");
            }
        }
        if (newStatus == 4 && !StringUtils.hasText(request.getRejectReason())) {
            throw new BusinessException("请填写淘汰原因");
        }

        // 5. 如果新状态是 3（已录用），执行乐观锁扣减名额
        if (newStatus == 3) {
            // 读取最新版本号
            Task freshTask = taskMapper.selectById(task.getId());
            if (freshTask.getRemainingQuota() == null || freshTask.getRemainingQuota() <= 0) {
                throw new BusinessException("名额不足，无法录用");
            }

            // 扣减名额（@Version 会自动处理 version 校验）
            freshTask.setRemainingQuota(freshTask.getRemainingQuota() - 1);
            freshTask.setUpdateTime(LocalDateTime.now());
            int rows = taskMapper.updateById(freshTask);
            if (rows == 0) {
                throw new BusinessException("名额不足或已被其他HR修改，请刷新后重试");
            }

            // 如果扣减后剩余名额为 0，更新职位状态为已满员（2）
            if (freshTask.getRemainingQuota() == 0) {
                Task fullTask = new Task();
                fullTask.setId(task.getId());
                fullTask.setStatus(2);
                fullTask.setVersion(freshTask.getVersion());
                fullTask.setUpdateTime(LocalDateTime.now());
                taskMapper.updateById(fullTask);
            }
        }

        // 6. 更新投递记录字段
        application.setStatus(newStatus);
        application.setHrId(userId);
        application.setInterviewTime(request.getInterviewTime());
        application.setInterviewLocation(request.getInterviewLocation());
        application.setRejectReason(request.getRejectReason());
        application.setHrNote(request.getHrNote());
        application.setUpdateTime(LocalDateTime.now());

        int appRows = taskApplicationMapper.updateById(application);
        if (appRows == 0) {
            throw new BusinessException("更新投递状态失败，请刷新后重试");
        }

        // 7. 创建通知给求职者
        String title;
        String content;
        Integer notifyType;
        switch (newStatus) {
            case 1:
                title = "面试邀请";
                content = String.format("您已被邀请面试，时间：%s，地点：%s",
                        request.getInterviewTime(), request.getInterviewLocation());
                notifyType = 1;
                break;
            case 2:
                title = "投递状态更新";
                content = "您的投递当前被标记为待定，HR 将稍后决定";
                notifyType = 0;
                break;
            case 3:
                title = "录用通知";
                content = "恭喜您已被录用！请查看详情并确认";
                notifyType = 2;
                break;
            case 4:
                title = "淘汰通知";
                content = String.format("很遗憾，您的投递未通过筛选。原因：%s",
                        request.getRejectReason());
                notifyType = 3;
                break;
            default:
                title = "投递状态更新";
                content = "您的投递状态已更新";
                notifyType = 0;
                break;
        }

        notificationService.sendNotification(
                application.getApplicantId(),  // 接收者 = 求职者 ID
                userId,                         // 发送者 = HR ID
                title,
                content,
                notifyType,
                application.getId()             // 业务关联 ID
        );

        // 8. 记录操作日志
        saveApplicationOperationLog(userId, application, currentStatus, newStatus, request);
    }

    /**
     * 保存投递状态变更操作日志
     */
    private void saveApplicationOperationLog(Long userId, TaskApplication application,
                                              Integer fromStatus, Integer newStatus,
                                              UpdateStatusRequest request) {
        String operationType;
        switch (newStatus) {
            case 1:
                operationType = OperationType.APPLICATION_INTERVIEW;
                break;
            case 2:
                operationType = OperationType.APPLICATION_PENDING;
                break;
            case 3:
                operationType = OperationType.APPLICATION_HIRE;
                break;
            case 4:
                operationType = OperationType.APPLICATION_REJECT;
                break;
            default:
                operationType = "APPLICATION_STATUS_UPDATE";
        }

        Map<String, Object> detail = new HashMap<>();
        detail.put("applicationId", application.getId());
        detail.put("taskId", application.getTaskId());
        detail.put("applicantId", application.getApplicantId());
        detail.put("fromStatus", fromStatus);
        detail.put("toStatus", newStatus);
        if (request.getInterviewTime() != null) {
            detail.put("interviewTime", request.getInterviewTime().toString());
        }
        if (StringUtils.hasText(request.getInterviewLocation())) {
            detail.put("interviewLocation", request.getInterviewLocation());
        }
        if (StringUtils.hasText(request.getRejectReason())) {
            detail.put("rejectReason", request.getRejectReason());
        }
        if (StringUtils.hasText(request.getHrNote())) {
            detail.put("hrNote", request.getHrNote());
        }

        String detailJson;
        try {
            detailJson = objectMapper.writeValueAsString(detail);
        } catch (Exception e) {
            detailJson = "{}";
        }

        OperationLog operationLog = new OperationLog();
        operationLog.setOperatorId(userId);
        operationLog.setOperationType(operationType);
        operationLog.setTargetType("TASK_APPLICATION");
        operationLog.setTargetId(String.valueOf(application.getId()));
        operationLog.setDetail(detailJson);
        operationLog.setCreateTime(LocalDateTime.now());
        operationLogService.saveLog(operationLog);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void complete(Long id, CompleteRequest request) {
        // 1. 查询投递记录
        TaskApplication application = taskApplicationMapper.selectById(id);
        if (application == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "投递记录不存在");
        }

        // 2. 校验状态为已录用（3）
        if (application.getStatus() != 3) {
            throw new BusinessException("仅已录用的投递可以进行结算确认");
        }

        // 3. 更新状态为已完成（5）
        application.setStatus(5);
        application.setHrNote(request.getHrNote());
        application.setUpdateTime(LocalDateTime.now());

        int rows = taskApplicationMapper.updateById(application);
        if (rows == 0) {
            throw new BusinessException("结算确认失败，请刷新后重试");
        }

        // 4. 记录结算完成日志
        Map<String, Object> detail = new HashMap<>();
        detail.put("applicationId", application.getId());
        detail.put("taskId", application.getTaskId());
        detail.put("applicantId", application.getApplicantId());
        detail.put("fromStatus", 3);
        detail.put("toStatus", 5);
        if (StringUtils.hasText(request.getHrNote())) {
            detail.put("hrNote", request.getHrNote());
        }

        String detailJson;
        try {
            detailJson = objectMapper.writeValueAsString(detail);
        } catch (Exception e) {
            detailJson = "{}";
        }

        OperationLog operationLog = new OperationLog();
        operationLog.setOperatorId(UserContext.getUserId());
        operationLog.setOperationType(OperationType.APPLICATION_COMPLETE);
        operationLog.setTargetType("TASK_APPLICATION");
        operationLog.setTargetId(String.valueOf(application.getId()));
        operationLog.setDetail(detailJson);
        operationLog.setCreateTime(LocalDateTime.now());
        operationLogService.saveLog(operationLog);
    }

    @Override
    public PageResult<TaskApplication> getMyApplications(int page, int pageSize) {
        Long userId = UserContext.getUserId();
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 10;

        Page<TaskApplication> pageParam = new Page<>(page, pageSize);
        pageParam.setOptimizeCountSql(false);

        LambdaQueryWrapper<TaskApplication> wrapper = new LambdaQueryWrapper<TaskApplication>()
                .eq(TaskApplication::getApplicantId, userId)
                .orderByDesc(TaskApplication::getCreateTime);

        IPage<TaskApplication> result = taskApplicationMapper.selectPage(pageParam, wrapper);
        return PageResult.of(result);
    }

    @Override
    public TaskApplication getApplicationDetail(Long id) {
        TaskApplication application = taskApplicationMapper.selectById(id);
        if (application == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "投递记录不存在");
        }

        // 校验访问权限：求职者本人或该职位所属企业的 HR
        Long userId = UserContext.getUserId();
        Integer userRole = UserContext.getRole();

        if (!application.getApplicantId().equals(userId)) {
            if (userRole == 1) {
                // HR 需校验是否是该职位所属企业的 HR
                Task task = taskMapper.selectById(application.getTaskId());
                if (task != null) {
                    Enterprise enterprise = enterpriseMapper.selectById(task.getEnterpriseId());
                    if (enterprise == null || !enterprise.getUserId().equals(userId)) {
                        throw new BusinessException(ApiResult.FORBIDDEN, "无权查看该投递详情");
                    }
                } else {
                    throw new BusinessException(ApiResult.FORBIDDEN, "无权查看该投递详情");
                }
            } else {
                throw new BusinessException(ApiResult.FORBIDDEN, "无权查看该投递详情");
            }
        }

        return application;
    }

    @Override
    public PageResult<TaskApplication> getTaskApplications(Long taskId, int page, int pageSize) {
        Long userId = UserContext.getUserId();
        Integer userRole = UserContext.getRole();

        // 校验：只有该职位所属企业的 HR 可以查看
        if (userRole != 1) {
            throw new BusinessException(ApiResult.FORBIDDEN, "仅 HR 可以查看职位投递列表");
        }

        Task task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "职位不存在");
        }

        Enterprise enterprise = enterpriseMapper.selectById(task.getEnterpriseId());
        if (enterprise == null || !enterprise.getUserId().equals(userId)) {
            throw new BusinessException(ApiResult.FORBIDDEN, "您无权查看该职位的投递列表");
        }

        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 10;

        Page<TaskApplication> pageParam = new Page<>(page, pageSize);
        pageParam.setOptimizeCountSql(false);

        LambdaQueryWrapper<TaskApplication> wrapper = new LambdaQueryWrapper<TaskApplication>()
                .eq(TaskApplication::getTaskId, taskId)
                .orderByDesc(TaskApplication::getCreateTime);

        IPage<TaskApplication> result = taskApplicationMapper.selectPage(pageParam, wrapper);
        return PageResult.of(result);
    }
}
