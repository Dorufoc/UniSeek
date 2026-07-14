package com.uniseek.admin.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.uniseek.admin.service.AdminService;
import com.uniseek.common.ApiResult;
import com.uniseek.constant.RoleConstant;
import com.uniseek.common.PageResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.common.util.UserContext;
import com.uniseek.dao.ComplaintMapper;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.NotificationMapper;
import com.uniseek.dao.OperationLogMapper;
import com.uniseek.dao.TaskApplicationMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.dao.UserMapper;
import com.uniseek.entity.Complaint;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.Notification;
import com.uniseek.entity.OperationLog;
import com.uniseek.entity.Task;
import com.uniseek.entity.TaskApplication;
import com.uniseek.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台服务实现
 */
@Service
public class AdminServiceImpl implements AdminService {

    private static final Logger log = LoggerFactory.getLogger(AdminServiceImpl.class);

    @Autowired
    private EnterpriseMapper enterpriseMapper;

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private OperationLogMapper operationLogMapper;

    @Autowired
    private ComplaintMapper complaintMapper;

    @Autowired
    private TaskApplicationMapper taskApplicationMapper;

    @Autowired
    private NotificationMapper notificationMapper;

    /**
     * 校验当前用户是否为管理员（role=9）
     */
    private void checkAdmin() {
        Integer role = UserContext.getRole();
        if (role == null || role != 9) {
            throw new BusinessException(ApiResult.FORBIDDEN, "无管理员权限");
        }
    }

    /**
     * 校验当前用户是否为超级管理员（role=99）
     */
    private void checkSuperAdmin() {
        Integer role = UserContext.getRole();
        if (role == null || role != 99) {
            throw new BusinessException(ApiResult.FORBIDDEN, "无超级管理员权限");
        }
    }

    // ==================== 企业审核 ====================

    @Override
    public PageResult<Enterprise> listEnterprises(int page, int pageSize, Integer auditStatus) {
        checkAdmin();
        QueryWrapper<Enterprise> wrapper = new QueryWrapper<>();
        if (auditStatus != null) {
            wrapper.eq("audit_status", auditStatus);
        }
        wrapper.orderByDesc("create_time");
        IPage<Enterprise> result = enterpriseMapper.selectPage(new Page<>(page, pageSize), wrapper);
        return PageResult.of(result);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void auditEnterprise(Long id, boolean approved, String rejectReason) {
        checkAdmin();
        Enterprise enterprise = enterpriseMapper.selectById(id);
        if (enterprise == null) {
            throw new BusinessException("企业记录不存在");
        }

        Long adminId = UserContext.getUserId();
        LocalDateTime now = LocalDateTime.now();

        if (approved) {
            // 审核通过
            enterprise.setAuditStatus(1);
            enterprise.setUpdateTime(now);
            enterprise.setAuditTime(now);
            enterpriseMapper.updateById(enterprise);

            // 发送通知给 HR
            sendNotification(enterprise.getUserId(), adminId,
                    "企业资质审核通过",
                    "您的企业「" + enterprise.getCompanyName() + "」资质认证已通过审核，现在可以发布职位了。",
                    0, enterprise.getId());

            log.info("管理员 {} 通过了企业 {} 的资质审核", adminId, enterprise.getId());
        } else {
            // 审核驳回
            if (rejectReason == null || rejectReason.trim().isEmpty()) {
                throw new BusinessException("驳回时必须填写原因");
            }
            enterprise.setAuditStatus(2);
            enterprise.setUpdateTime(now);
            enterpriseMapper.updateById(enterprise);

            // 发送通知给 HR
            sendNotification(enterprise.getUserId(), adminId,
                    "企业资质审核未通过",
                    "您的企业「" + enterprise.getCompanyName() + "」资质认证未通过审核，原因：" + rejectReason,
                    0, enterprise.getId());

            log.info("管理员 {} 驳回了企业 {} 的资质审核，原因：{}", adminId, enterprise.getId(), rejectReason);
        }
    }

    // ==================== 职位审核 ====================

    @Override
    public PageResult<Task> listPendingTasks(int page, int pageSize) {
        checkAdmin();
        QueryWrapper<Task> wrapper = new QueryWrapper<>();
        wrapper.eq("status", 0); // 待审核
        wrapper.orderByDesc("create_time");
        IPage<Task> result = taskMapper.selectPage(new Page<>(page, pageSize), wrapper);
        return PageResult.of(result);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void auditTask(Long id, boolean approved, String rejectReason) {
        checkAdmin();
        Task task = taskMapper.selectById(id);
        if (task == null) {
            throw new BusinessException("职位不存在");
        }

        Long adminId = UserContext.getUserId();
        LocalDateTime now = LocalDateTime.now();

        if (approved) {
            // 审核通过，发布职位
            task.setStatus(1); // 已发布
            task.setUpdateTime(now);
            task.setAuditTime(now);
            taskMapper.updateById(task);

            // 发送通知给 HR
            sendEnterpriseNotification(task.getEnterpriseId(), adminId,
                    "职位审核通过",
                    "您的职位「" + task.getTitle() + "」已通过审核并发布。",
                    0, task.getId());

            log.info("管理员 {} 通过了职位 {} 的审核并发布", adminId, task.getId());
        } else {
            // 审核驳回（状态保持 0 不变，但记录驳回原因）
            if (rejectReason == null || rejectReason.trim().isEmpty()) {
                throw new BusinessException("驳回时必须填写原因");
            }
            // 状态保持 0（待审核），通过 description 记录驳回原因
            task.setUpdateTime(now);
            // TODO: Todo 20 添加 reject_reason 字段后设置驳回原因
            taskMapper.updateById(task);

            // 发送通知给 HR
            sendEnterpriseNotification(task.getEnterpriseId(), adminId,
                    "职位审核未通过",
                    "您的职位「" + task.getTitle() + "」未通过审核，原因：" + rejectReason,
                    0, task.getId());

            log.info("管理员 {} 驳回了职位 {} 的审核，原因：{}", adminId, task.getId(), rejectReason);
        }
    }

    // ==================== 用户管理 ====================

    @Override
    public PageResult<User> listUsers(int page, int pageSize, String keyword,
                                       Integer role, Integer status) {
        checkAdmin();
        QueryWrapper<User> wrapper = new QueryWrapper<>();
        if (keyword != null && !keyword.trim().isEmpty()) {
            wrapper.and(w -> w.like("phone", keyword)
                    .or().like("email", keyword)
                    .or().like("nickname", keyword));
        }
        if (role != null) {
            wrapper.eq("role", role);
        }
        if (status != null) {
            wrapper.eq("status", status);
        }
        wrapper.orderByDesc("create_time");
        IPage<User> result = userMapper.selectPage(new Page<>(page, pageSize), wrapper);
        return PageResult.of(result);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateUserStatus(Long id, Integer status) {
        checkAdmin();
        User user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        if (status != 0 && status != 1) {
            throw new BusinessException("状态值不合法，仅支持 0（禁用）或 1（正常）");
        }

        user.setStatus(status);
        user.setUpdateTime(LocalDateTime.now());
        userMapper.updateById(user);

        Long adminId = UserContext.getUserId();
        String statusText = status == 0 ? "禁用" : "启用";
        log.info("管理员 {} {}了用户 {}", adminId, statusText, id);

        // 发送通知给被操作用户
        sendNotification(id, adminId,
                "账号" + statusText,
                "您的账号已被管理员" + statusText + "，如有疑问请联系客服。",
                0, null);
    }

    // ==================== 数据统计 ====================

    @Override
    public Map<String, Object> getStatistics(LocalDateTime startDate, LocalDateTime endDate) {
        checkAdmin();

        // 如果没有传日期，默认最近 30 天
        if (endDate == null) {
            endDate = LocalDateTime.now();
        }
        if (startDate == null) {
            startDate = endDate.minusDays(30);
        }

        // 汇总数据
        Map<String, Object> summary = new HashMap<>();

        // 用户总数
        Integer totalUsers = userMapper.selectCount(null);
        summary.put("totalUsers", totalUsers != null ? totalUsers : 0);

        // 求职者数量
        QueryWrapper<User> seekerWrapper = new QueryWrapper<>();
        seekerWrapper.eq("role", 0);
        Integer totalSeekers = userMapper.selectCount(seekerWrapper);
        summary.put("totalSeekers", totalSeekers != null ? totalSeekers : 0);

        // HR 数量
        QueryWrapper<User> hrWrapper = new QueryWrapper<>();
        hrWrapper.eq("role", 1);
        Integer totalHr = userMapper.selectCount(hrWrapper);
        summary.put("totalHr", totalHr != null ? totalHr : 0);

        // 企业认证数量
        Integer totalEnterprises = enterpriseMapper.selectCount(null);
        summary.put("totalEnterprises", totalEnterprises != null ? totalEnterprises : 0);

        // 职位总数
        Integer totalTasks = taskMapper.selectCount(null);
        summary.put("totalTasks", totalTasks != null ? totalTasks : 0);

        // 已发布职位数
        QueryWrapper<Task> publishedTaskWrapper = new QueryWrapper<>();
        publishedTaskWrapper.eq("status", 1);
        Integer publishedTasks = taskMapper.selectCount(publishedTaskWrapper);
        summary.put("publishedTasks", publishedTasks != null ? publishedTasks : 0);

        // 投递总数
        Integer totalApplications = taskApplicationMapper.selectCount(null);
        summary.put("totalApplications", totalApplications != null ? totalApplications : 0);

        // 投诉总数
        Integer totalComplaints = complaintMapper.selectCount(null);
        summary.put("totalComplaints", totalComplaints != null ? totalComplaints : 0);

        // 每日明细数据（按日期分组统计）
        List<Map<String, Object>> dailyList = getDailyStatistics(startDate, endDate);

        Map<String, Object> result = new HashMap<>();
        result.put("summary", summary);
        result.put("dailyList", dailyList);
        result.put("startDate", startDate.toLocalDate().toString());
        result.put("endDate", endDate.toLocalDate().toString());

        return result;
    }

    /**
     * 获取每日统计数据
     */
    private List<Map<String, Object>> getDailyStatistics(LocalDateTime startDate, LocalDateTime endDate) {
        List<Map<String, Object>> dailyList = new ArrayList<>();

        LocalDate startLocalDate = startDate.toLocalDate();
        LocalDate endLocalDate = endDate.toLocalDate();

        // 遍历每一天，统计当日注册数、企业认证数、职位发布数、投递数
        for (LocalDate date = startLocalDate; !date.isAfter(endLocalDate); date = date.plusDays(1)) {
            LocalDateTime dayStart = date.atStartOfDay();
            LocalDateTime dayEnd = date.atTime(LocalTime.MAX);

            Map<String, Object> dayData = new HashMap<>();
            dayData.put("date", date.toString());

            // 当日注册用户数
            QueryWrapper<User> userWrapper = new QueryWrapper<>();
            userWrapper.between("create_time", dayStart, dayEnd);
            int newUsers = userMapper.selectCount(userWrapper);
            dayData.put("newUsers", newUsers);

            // 当日企业认证数
            QueryWrapper<Enterprise> entWrapper = new QueryWrapper<>();
            entWrapper.between("create_time", dayStart, dayEnd);
            int newEnterprises = enterpriseMapper.selectCount(entWrapper);
            dayData.put("newEnterprises", newEnterprises);

            // 当日发布职位数
            QueryWrapper<Task> taskWrapper = new QueryWrapper<>();
            taskWrapper.between("create_time", dayStart, dayEnd);
            int newTasks = taskMapper.selectCount(taskWrapper);
            dayData.put("newTasks", newTasks);

            // 当日投递数
            QueryWrapper<TaskApplication> appWrapper = new QueryWrapper<>();
            appWrapper.between("create_time", dayStart, dayEnd);
            int newApplications = taskApplicationMapper.selectCount(appWrapper);
            dayData.put("newApplications", newApplications);

            dailyList.add(dayData);
        }

        return dailyList;
    }

    // ==================== 操作日志 ====================

    @Override
    public PageResult<OperationLog> listOperationLogs(int page, int pageSize, Long operatorId,
                                                       String operationType, String targetType,
                                                       String targetId, LocalDateTime startTime,
                                                       LocalDateTime endTime) {
        checkAdmin();
        QueryWrapper<OperationLog> wrapper = new QueryWrapper<>();
        if (operatorId != null) {
            wrapper.eq("operator_id", operatorId);
        }
        if (operationType != null && !operationType.trim().isEmpty()) {
            wrapper.eq("operation_type", operationType);
        }
        if (targetType != null && !targetType.trim().isEmpty()) {
            wrapper.eq("target_type", targetType);
        }
        if (targetId != null && !targetId.trim().isEmpty()) {
            wrapper.eq("target_id", targetId);
        }
        if (startTime != null) {
            wrapper.ge("create_time", startTime);
        }
        if (endTime != null) {
            wrapper.le("create_time", endTime);
        }
        wrapper.orderByDesc("create_time");
        IPage<OperationLog> result = operationLogMapper.selectPage(new Page<>(page, pageSize), wrapper);
        return PageResult.of(result);
    }

    // ==================== 投诉处理 ====================

    @Override
    public PageResult<Complaint> listComplaints(int page, int pageSize, Integer status,
                                                 Integer targetType) {
        checkAdmin();
        QueryWrapper<Complaint> wrapper = new QueryWrapper<>();
        if (status != null) {
            wrapper.eq("status", status);
        }
        if (targetType != null) {
            wrapper.eq("target_type", targetType);
        }
        wrapper.orderByDesc("create_time");
        IPage<Complaint> result = complaintMapper.selectPage(new Page<>(page, pageSize), wrapper);
        return PageResult.of(result);
    }

    @Override
    public Map<String, Object> getComplaintDetail(Long id) {
        checkAdmin();
        Complaint complaint = complaintMapper.selectById(id);
        if (complaint == null) {
            throw new BusinessException("投诉记录不存在");
        }

        Map<String, Object> detail = new HashMap<>();
        detail.put("complaint", complaint);

        // 查询投诉人信息
        User complainant = userMapper.selectById(complaint.getComplainantId());
        if (complainant != null) {
            Map<String, Object> complainantInfo = new HashMap<>();
            complainantInfo.put("id", complainant.getId());
            complainantInfo.put("nickname", complainant.getNickname());
            complainantInfo.put("phone", complainant.getPhone());
            complainantInfo.put("email", complainant.getEmail());
            detail.put("complainantInfo", complainantInfo);
        }

        // 查询被投诉对象标题
        String targetTitle = resolveTargetTitle(complaint.getTargetType(), complaint.getTargetId());
        detail.put("targetTitle", targetTitle);

        return detail;
    }

    /**
     * 根据目标类型和 ID 解析被投诉对象的标题
     */
    private String resolveTargetTitle(Integer targetType, Long targetId) {
        if (targetType == null || targetId == null) {
            return "未知";
        }
        switch (targetType) {
            case 0: // 职位
                Task task = taskMapper.selectById(targetId);
                return task != null ? task.getTitle() : "职位（已删除）";
            case 1: // 企业
                Enterprise enterprise = enterpriseMapper.selectById(targetId);
                return enterprise != null ? enterprise.getCompanyName() : "企业（已删除）";
            case 2: // 用户
                User user = userMapper.selectById(targetId);
                return user != null ? user.getNickname() : "用户（已删除）";
            default:
                return "未知";
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void handleComplaint(Long id, Integer status, String handleResult) {
        checkAdmin();
        Complaint complaint = complaintMapper.selectById(id);
        if (complaint == null) {
            throw new BusinessException("投诉记录不存在");
        }
        if (status != 1 && status != 2) {
            throw new BusinessException("处理状态不合法，仅支持 1（处理中）或 2（已结案）");
        }
        if (handleResult == null || handleResult.trim().isEmpty()) {
            throw new BusinessException("处理结果不能为空");
        }

        Long adminId = UserContext.getUserId();
        LocalDateTime now = LocalDateTime.now();

        complaint.setStatus(status);
        complaint.setHandlerId(adminId);
        complaint.setHandleResult(handleResult);
        complaint.setUpdateTime(now);
        complaintMapper.updateById(complaint);

        // 发送通知给投诉人
        String statusText = status == 1 ? "正在处理中" : "已结案";
        sendNotification(complaint.getComplainantId(), adminId,
                "投诉处理进度更新",
                "您提交的投诉已被管理员受理，" + statusText + "。处理结果：" + handleResult,
                0, complaint.getId());

        log.info("管理员 {} 处理了投诉 {}，状态：{}，结果：{}", adminId, id, status, handleResult);
    }

    // ==================== 超级管理员 - 管理员账号管理 ====================

    @Override
    public List<User> listAdmins() {
        checkSuperAdmin();
        QueryWrapper<User> wrapper = new QueryWrapper<>();
        wrapper.in("role", 9, 99);
        wrapper.orderByDesc("create_time");
        return userMapper.selectList(wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateUserRole(Long userId, Integer newRole) {
        checkSuperAdmin();

        // 禁止创建超级管理员
        if (newRole != null && newRole == 99) {
            throw new BusinessException("不允许创建超级管理员账号");
        }

        // 禁止修改自身角色
        Long currentUserId = UserContext.getUserId();
        if (currentUserId.equals(userId)) {
            throw new BusinessException("不能修改自己的角色");
        }

        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }

        user.setRole(newRole);
        user.setUpdateTime(LocalDateTime.now());
        userMapper.updateById(user);

        Long adminId = UserContext.getUserId();
        log.info("超级管理员 {} 修改了用户 {} 的角色为 {}", adminId, userId, newRole);
    }

    // ==================== 通知发送辅助 ====================

    /**
     * 发送系统通知
     */
    private void sendNotification(Long receiverId, Long senderId, String title,
                                   String content, Integer type, Long bizId) {
        Notification notification = new Notification();
        notification.setReceiverId(receiverId);
        notification.setSenderId(senderId);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setType(type);
        notification.setIsRead(0);
        notification.setBizId(bizId);
        notification.setCreateTime(LocalDateTime.now());
        notificationMapper.insert(notification);
    }

    /**
     * 向企业所属 HR 发送通知
     * 查询企业对应的 userId（即 HR）后发送通知
     */
    private void sendEnterpriseNotification(Long enterpriseId, Long senderId,
                                             String title, String content,
                                             Integer type, Long bizId) {
        Enterprise enterprise = enterpriseMapper.selectById(enterpriseId);
        if (enterprise != null && enterprise.getUserId() != null) {
            sendNotification(enterprise.getUserId(), senderId, title, content, type, bizId);
        }
    }
}
