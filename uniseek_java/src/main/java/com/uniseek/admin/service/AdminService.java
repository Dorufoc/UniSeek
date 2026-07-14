package com.uniseek.admin.service;

import com.uniseek.common.PageResult;
import com.uniseek.entity.Complaint;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.OperationLog;
import com.uniseek.entity.Task;
import com.uniseek.entity.User;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 管理后台服务接口
 */
public interface AdminService {

    // ==================== 企业审核 ====================

    /**
     * 分页查询企业审核列表
     *
     * @param page       页码
     * @param pageSize   每页条数
     * @param auditStatus 审核状态筛选（可为 null）
     * @return 企业分页结果
     */
    PageResult<Enterprise> listEnterprises(int page, int pageSize, Integer auditStatus);

    /**
     * 审核企业资质
     *
     * @param id           企业记录 ID
     * @param approved     是否通过（true=通过，false=驳回）
     * @param rejectReason 驳回原因（驳回时必填）
     */
    void auditEnterprise(Long id, boolean approved, String rejectReason);

    // ==================== 职位审核 ====================

    /**
     * 分页查询待审核职位列表
     *
     * @param page     页码
     * @param pageSize 每页条数
     * @return 职位分页结果
     */
    PageResult<Task> listPendingTasks(int page, int pageSize);

    /**
     * 审核职位
     *
     * @param id           职位 ID
     * @param approved     是否通过
     * @param rejectReason 驳回原因（驳回时必填）
     */
    void auditTask(Long id, boolean approved, String rejectReason);

    // ==================== 用户管理 ====================

    /**
     * 分页查询用户列表
     *
     * @param page    页码
     * @param pageSize 每页条数
     * @param keyword 关键词（手机号/邮箱/昵称模糊搜索，可为 null）
     * @param role    角色筛选（可为 null）
     * @param status  状态筛选（可为 null）
     * @return 用户分页结果
     */
    PageResult<User> listUsers(int page, int pageSize, String keyword, Integer role, Integer status);

    /**
     * 启用/禁用用户
     *
     * @param id     用户 ID
     * @param status 目标状态（0 禁用 / 1 正常）
     */
    void updateUserStatus(Long id, Integer status);

    // ==================== 数据统计 ====================

    /**
     * 获取数据统计（支持日期筛选）
     *
     * @param startDate 开始日期（可为 null）
     * @param endDate   结束日期（可为 null）
     * @return 包含 summary（汇总）和 dailyList（每日明细）的 Map
     */
    Map<String, Object> getStatistics(LocalDateTime startDate, LocalDateTime endDate);

    // ==================== 操作日志 ====================

    /**
     * 分页查询操作日志
     *
     * @param page          页码
     * @param pageSize      每页条数
     * @param operatorId    操作人 ID（可为 null）
     * @param operationType 操作类型（可为 null）
     * @param targetType    目标类型（可为 null）
     * @param targetId      目标 ID（可为 null）
     * @param startTime     开始时间（可为 null）
     * @param endTime       结束时间（可为 null）
     * @return 操作日志分页结果
     */
    PageResult<OperationLog> listOperationLogs(int page, int pageSize, Long operatorId,
                                                String operationType, String targetType,
                                                String targetId, LocalDateTime startTime,
                                                LocalDateTime endTime);

    // ==================== 投诉处理 ====================

    /**
     * 分页查询投诉列表
     *
     * @param page       页码
     * @param pageSize   每页条数
     * @param status     处理状态筛选（可为 null）
     * @param targetType 被投诉对象类型筛选（可为 null）
     * @return 投诉分页结果
     */
    PageResult<Complaint> listComplaints(int page, int pageSize, Integer status, Integer targetType);

    /**
     * 获取投诉详情（含投诉人信息 + 被投诉对象标题）
     *
     * @param id 投诉 ID
     * @return 投诉详情 Map
     */
    Map<String, Object> getComplaintDetail(Long id);

    /**
     * 处理投诉
     *
     * @param id           投诉 ID
     * @param status       目标状态（1 处理中 / 2 已结案）
     * @param handleResult 处理结果
     */
    void handleComplaint(Long id, Integer status, String handleResult);

    // ==================== 超级管理员 - 管理员账号管理 ====================

    /**
     * 获取所有管理员账号列表（role=9 或 role=99）
     *
     * @return 管理员用户列表
     */
    List<User> listAdmins();

    /**
     * 超级管理员修改用户角色
     *
     * @param userId  目标用户 ID
     * @param newRole 新角色值
     */
    void updateUserRole(Long userId, Integer newRole);
}
