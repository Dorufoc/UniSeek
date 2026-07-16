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
import com.uniseek.dao.RealNameAuthMapper;
import com.uniseek.entity.Complaint;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.Notification;
import com.uniseek.entity.OperationLog;
import com.uniseek.entity.RealNameAuth;
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

    @Autowired
    private RealNameAuthMapper realNameAuthMapper;

    /**
     * 校验当前用户是否为管理员（role >= 9，含超级管理员）
     */
    private void checkAdmin() {
        Integer role = UserContext.getRole();
        if (role == null || role < 9) {
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
        if (enterprise.getAuditStatus() != 0) {
            throw new BusinessException("该企业申请已审核，不可重复操作");
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
        if (task.getStatus() != 0) {
            throw new BusinessException("该职位已审核，不可重复操作");
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

        // 填充实名认证状态
        for (User user : result.getRecords()) {
            RealNameAuth auth = realNameAuthMapper.selectOne(
                    new QueryWrapper<RealNameAuth>()
                            .eq("user_id", user.getId())
                            .eq("status", 1));
            user.setRealNameAuth(auth != null);
        }

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
        if (user.getRole() == 99) {
            throw new BusinessException("超级管理员账号不可被禁用");
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

    @Override
    public List<Map<String, Object>> getHotTasks() {
        return taskMapper.selectHotTasks();
    }

    @Override
    public List<Map<String, Object>> getCategoryDistribution() {
        return taskMapper.selectCategoryDistribution();
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

    @Override
    public List<Map<String, Object>> getTalentFlow() {
        return taskMapper.selectTalentFlow();
    }

    @Override
    public List<Map<String, Object>> getLatestActivity() {
        List<Map<String, Object>> result = new ArrayList<>();
        QueryWrapper<OperationLog> wrapper = new QueryWrapper<>();
        wrapper.orderByDesc("create_time").last("LIMIT 10");
        List<OperationLog> logs = operationLogMapper.selectList(wrapper);

        for (OperationLog log : logs) {
            Map<String, Object> item = new HashMap<>();
            item.put("id", log.getId());
            item.put("time", log.getCreateTime() != null ? log.getCreateTime().toString().replace("T", " ") : "");

            // 查询操作人名称（脱敏）
            String userName = resolveOperatorName(log.getOperatorId());
            item.put("userName", userName);

            // 查询目标标题（岗位名/公司名等）
            String targetTitle = resolveActivityTarget(log);
            item.put("target", targetTitle);

            // 构建完整消息
            String message = buildActivityMessage(log, userName, targetTitle);
            item.put("message", message);
            result.add(item);
        }
        return result;
    }

    /**
     * 脱敏用户名：显示首字 + *，如 "张*" "张*芒"
     */
    private String desensitizeName(String name) {
        if (name == null || name.trim().isEmpty()) return "未知用户";
        name = name.trim();
        if (name.length() == 1) return name;
        if (name.length() == 2) return name.charAt(0) + "*";
        return name.charAt(0) + "*" + name.substring(name.length() - 1);
    }

    /**
     * 根据操作人 ID 查询并脱敏用户名
     */
    private String resolveOperatorName(Long operatorId) {
        if (operatorId == null) return "系统";
        User user = userMapper.selectById(operatorId);
        if (user == null || user.getNickname() == null || user.getNickname().trim().isEmpty()) {
            return "未知用户";
        }
        return desensitizeName(user.getNickname());
    }

    /**
     * 根据操作日志解析目标标题（岗位名 @ 公司名）
     */
    private String resolveActivityTarget(OperationLog log) {
        String type = log.getOperationType();
        Long targetId = log.getTargetId();
        if (targetId == null) return "";

        // 职位相关：通过 targetId 查 task 表获取标题和公司名
        if ("TASK_PUBLISH".equals(type) || "TASK_AUDIT".equals(type) || "TASK_OFFLINE".equals(type)) {
            Task task = taskMapper.selectById(targetId);
            if (task != null) {
                String title = task.getTitle();
                String company = "";
                if (task.getEnterpriseId() != null) {
                    Enterprise ent = enterpriseMapper.selectById(task.getEnterpriseId());
                    if (ent != null) company = ent.getCompanyName();
                }
                return title + (company.isEmpty() ? "" : " @ " + company);
            }
        }

        // 投递相关：targetId 是 applicationId，需查 task_application 获取 taskId
        if ("APPLICATION_DELIVER".equals(type) || "APPLICATION_INTERVIEW".equals(type)
            || "APPLICATION_PENDING".equals(type) || "APPLICATION_HIRE".equals(type)
            || "APPLICATION_REJECT".equals(type) || "APPLICATION_COMPLETE".equals(type)) {
            TaskApplication app = taskApplicationMapper.selectById(targetId);
            if (app != null && app.getTaskId() != null) {
                Task task = taskMapper.selectById(app.getTaskId());
                if (task != null) {
                    String title = task.getTitle();
                    String company = "";
                    if (task.getEnterpriseId() != null) {
                        Enterprise ent = enterpriseMapper.selectById(task.getEnterpriseId());
                        if (ent != null) company = ent.getCompanyName();
                    }
                    return title + (company.isEmpty() ? "" : " @ " + company);
                }
            }
        }

        // 企业相关
        if ("ENTERPRISE_SUBMIT".equals(type) || "ENTERPRISE_AUDIT".equals(type)) {
            Enterprise ent = enterpriseMapper.selectById(targetId);
            if (ent != null) return ent.getCompanyName();
        }

        return "";
    }

    private String buildActivityMessage(OperationLog log, String userName, String targetTitle) {
        String type = log.getOperationType();
        if (type == null) return "系统操作记录";

        switch (type) {
            case "REGISTER":
            case "USER_REGISTER":
                return userName + " 注册了" + (targetTitle.isEmpty() ? "账号" : targetTitle);
            case "LOGIN":
            case "USER_LOGIN":
                return userName + " 登录了系统";
            case "LOGOUT":
                return userName + " 退出了系统";
            case "REAL_NAME_AUTH":
                return userName + " 完成了实名认证";
            case "CHANGE_PASSWORD":
                return userName + " 修改了登录密码";
            case "UPDATE_PHONE":
                return userName + " 修改了绑定手机号";
            case "UPDATE_EMAIL":
                return userName + " 修改了绑定邮箱";
            case "SAVE_RESUME":
                return userName + " 更新了简历";
            case "UPLOAD_RESUME":
                return userName + " 上传了附件简历";
            case "ENTERPRISE_SUBMIT":
                return (targetTitle.isEmpty() ? "企业" : targetTitle) + " 提交了资质认证申请";
            case "ENTERPRISE_AUDIT":
                return (targetTitle.isEmpty() ? "企业" : targetTitle) + " 资质审核通过";
            case "TASK_PUBLISH":
                return "新职位发布：" + (targetTitle.isEmpty() ? "未知岗位" : targetTitle);
            case "TASK_AUDIT":
                return "职位审核通过：" + (targetTitle.isEmpty() ? "未知岗位" : targetTitle);
            case "TASK_OFFLINE":
                return "职位已下架：" + (targetTitle.isEmpty() ? "未知岗位" : targetTitle);
            case "APPLICATION_DELIVER":
                return userName + " 投递了 " + (targetTitle.isEmpty() ? "新岗位" : targetTitle);
            case "APPLICATION_INTERVIEW":
                return userName + " 收到面试邀请：" + (targetTitle.isEmpty() ? "" : targetTitle);
            case "APPLICATION_PENDING":
                return userName + " 投递状态已更新";
            case "APPLICATION_HIRE":
                return userName + " 成功入职 " + (targetTitle.isEmpty() ? "新岗位" : targetTitle);
            case "APPLICATION_REJECT":
                return userName + " 未通过筛选：" + (targetTitle.isEmpty() ? "" : targetTitle);
            case "APPLICATION_COMPLETE":
                return userName + " 已完成工作结算：" + (targetTitle.isEmpty() ? "" : targetTitle);
            case "COMPLAINT_HANDLE":
                return "投诉已处理完成";
            case "ADMIN_SET_ROLE":
                return userName + " 调整了用户角色";
            default:
                if (type != null && !type.isEmpty()) {
                    String readable = type
                        .replace("USER_", "")
                        .replace("APPLICATION_", "")
                        .replace("ENTERPRISE_", "")
                        .replace("TASK_", "")
                        .replace("COMPLAINT_", "")
                        .replace("REAL_NAME_", "")
                        .replace("ADMIN_", "")
                        .replace("_", " ")
                        .toLowerCase();
                    if (readable.length() > 0) {
                        readable = readable.substring(0, 1).toUpperCase() + readable.substring(1);
                    }
                    return userName + " " + readable;
                }
                return "系统操作记录";
        }
    }

    @Override
    public Map<String, Object> getScreenSummary(String range) {
        Map<String, Object> data = new HashMap<>();

        // 1. 汇总数据
        Map<String, Object> summary = new HashMap<>();

        Integer totalUsers = userMapper.selectCount(null);
        summary.put("totalUsers", totalUsers != null ? totalUsers : 0);

        Integer totalEnterprises = enterpriseMapper.selectCount(null);
        summary.put("totalEnterprises", totalEnterprises != null ? totalEnterprises : 0);

        Integer totalTasks = taskMapper.selectCount(null);
        summary.put("totalTasks", totalTasks != null ? totalTasks : 0);

        QueryWrapper<Task> publishedWrapper = new QueryWrapper<>();
        publishedWrapper.eq("status", 1);
        Integer publishedTasks = taskMapper.selectCount(publishedWrapper);
        summary.put("publishedTasks", publishedTasks != null ? publishedTasks : 0);

        Integer totalApplications = taskApplicationMapper.selectCount(null);
        summary.put("totalApplications", totalApplications != null ? totalApplications : 0);

        data.put("summary", summary);

        // 2. 今日投递数
        QueryWrapper<TaskApplication> todayWrapper = new QueryWrapper<>();
        todayWrapper.apply("DATE(create_time) = CURDATE()");
        Integer todayDeliveries = taskApplicationMapper.selectCount(todayWrapper);
        data.put("latestDeliveries", todayDeliveries != null ? todayDeliveries : 0);

        // 3. 按范围生成趋势数据
        data.put("dailyList", generateTrendData(range));

        return data;
    }

    private List<Map<String, Object>> generateTrendData(String range) {
        List<Map<String, Object>> result = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        int days = 7;
        switch (range != null ? range : "7d") {
            case "24h":
                for (int i = 23; i >= 0; i--) {
                    LocalDateTime start = now.minusHours(i + 1);
                    LocalDateTime end = now.minusHours(i);
                    Map<String, Object> item = buildTimeSlotData(start, end);
                    item.put("date", start.getHour() + ":00");
                    result.add(item);
                }
                return result;
            case "30d":
                days = 30;
                break;
            case "12m":
                for (int i = 11; i >= 0; i--) {
                    LocalDateTime start = now.minusMonths(i).withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
                    LocalDateTime end = i == 0 ? now : start.plusMonths(1);
                    Map<String, Object> item = buildTimeSlotData(start, end);
                    item.put("date", start.getYear() + "-" + String.format("%02d", start.getMonthValue()));
                    result.add(item);
                }
                return result;
            case "10y":
                for (int i = 9; i >= 0; i--) {
                    LocalDateTime start = now.minusYears(i).withDayOfYear(1).withHour(0).withMinute(0).withSecond(0);
                    LocalDateTime end = i == 0 ? now : start.plusYears(1);
                    Map<String, Object> item = buildTimeSlotData(start, end);
                    item.put("date", String.valueOf(start.getYear()));
                    result.add(item);
                }
                return result;
            default:
                break;
        }

        for (int i = days - 1; i >= 0; i--) {
            LocalDateTime start = now.minusDays(i).withHour(0).withMinute(0).withSecond(0);
            LocalDateTime end = i == 0 ? now : start.plusDays(1);
            Map<String, Object> item = buildTimeSlotData(start, end);
            item.put("date", start.toLocalDate().toString());
            result.add(item);
        }
        return result;
    }

    private Map<String, Object> buildTimeSlotData(LocalDateTime start, LocalDateTime end) {
        Map<String, Object> item = new HashMap<>();

        QueryWrapper<User> uWrap = new QueryWrapper<>();
        uWrap.between("create_time", start, end);
        item.put("newUsers", userMapper.selectCount(uWrap));

        QueryWrapper<Task> tWrap = new QueryWrapper<>();
        tWrap.between("create_time", start, end);
        item.put("newTasks", taskMapper.selectCount(tWrap));

        QueryWrapper<TaskApplication> aWrap = new QueryWrapper<>();
        aWrap.between("create_time", start, end);
        item.put("newApplications", taskApplicationMapper.selectCount(aWrap));

        QueryWrapper<TaskApplication> iWrap = new QueryWrapper<>();
        iWrap.between("update_time", start, end).eq("status", 1);
        item.put("newInterviews", taskApplicationMapper.selectCount(iWrap));

        QueryWrapper<TaskApplication> eWrap = new QueryWrapper<>();
        eWrap.between("update_time", start, end).eq("status", 3);
        item.put("newEntries", taskApplicationMapper.selectCount(eWrap));

        QueryWrapper<Enterprise> entWrap = new QueryWrapper<>();
        entWrap.between("audit_time", start, end).eq("audit_status", 1);
        item.put("newEnterprises", enterpriseMapper.selectCount(entWrap));

        return item;
    }

    @Override
    public Map<String, Object> getApplicationFunnel() {
        Map<String, Object> result = new HashMap<>();

        Integer total = taskApplicationMapper.selectCount(null);
        result.put("total", total != null ? total : 0);

        int[] statuses = {0, 1, 2, 3, 4, 5};
        String[] statusNames = {"已投递", "待面试", "面试通过", "已录用", "已淘汰", "已完成"};

        List<Map<String, Object>> statusList = new ArrayList<>();
        for (int i = 0; i < statuses.length; i++) {
            QueryWrapper<TaskApplication> wrapper = new QueryWrapper<>();
            wrapper.eq("status", statuses[i]);
            Integer count = taskApplicationMapper.selectCount(wrapper);
            Map<String, Object> item = new HashMap<>();
            item.put("status", statuses[i]);
            item.put("name", statusNames[i]);
            item.put("count", count != null ? count : 0);
            statusList.add(item);
        }
        result.put("statusList", statusList);

        QueryWrapper<TaskApplication> todayWrapper = new QueryWrapper<>();
        todayWrapper.apply("DATE(create_time) = CURDATE()");
        Integer todayNew = taskApplicationMapper.selectCount(todayWrapper);
        result.put("todayNew", todayNew != null ? todayNew : 0);

        return result;
    }

    @Override
    public Map<String, Object> getEnterpriseSummary() {
        Map<String, Object> result = new HashMap<>();
        
        // 1. 企业资质审核状态
        int[] auditStatuses = {0, 1, 2};
        String[] auditNames = {"待审核", "已认证", "已驳回"};
        List<Map<String, Object>> auditList = new ArrayList<>();
        for (int i = 0; i < auditStatuses.length; i++) {
            QueryWrapper<Enterprise> wrapper = new QueryWrapper<>();
            wrapper.eq("audit_status", auditStatuses[i]);
            Integer count = enterpriseMapper.selectCount(wrapper);
            Map<String, Object> item = new HashMap<>();
            item.put("status", auditStatuses[i]);
            item.put("name", auditNames[i]);
            item.put("count", count != null ? count : 0);
            auditList.add(item);
        }
        result.put("auditList", auditList);
        Integer totalEnterprise = enterpriseMapper.selectCount(null);
        result.put("totalEnterprise", totalEnterprise != null ? totalEnterprise : 0);
        
        // 2. 实名认证率
        Integer totalUser = userMapper.selectCount(null);
        QueryWrapper<RealNameAuth> authWrapper = new QueryWrapper<>();
        authWrapper.eq("status", 1);
        Integer authedCount = realNameAuthMapper.selectCount(authWrapper);
        result.put("totalUser", totalUser != null ? totalUser : 0);
        result.put("authedCount", authedCount != null ? authedCount : 0);
        result.put("unauthedCount", (totalUser != null ? totalUser : 0) - (authedCount != null ? authedCount : 0));
        
        return result;
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
