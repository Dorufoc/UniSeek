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
    PageResult<Enterprise> listEnterprises(int page, int pageSize, Integer auditStatus, String keyword);

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
     * 分页查询职位列表（支持状态筛选、关键字搜索、含发布企业名称）
     *
     * @param page     页码
     * @param pageSize 每页条数
     * @param status   状态筛选（可为 null，查询全部）
     * @param keyword  关键字搜索职位标题（可为 null）
     * @return 职位分页结果（含 enterpriseName）
     */
    PageResult<Task> listTasks(int page, int pageSize, Integer status, String keyword);

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

    /**
     * 获取职位大类需求占比（按顶级分类分组统计，仅统计招聘中职位）
     */
    List<Map<String, Object>> getCategoryDistribution();

    /**
     * 获取热门岗位 TOP10（按投递量倒序）
     */
    List<Map<String, Object>> getHotTasks();

    /**
     * 获取最新动态（operation_log 最新 10 条，拼接可读文案）
     *
     * @return 动态列表（包含 id、message、time）
     */
    List<Map<String, Object>> getLatestActivity();

    /**
     * 获取人才流向数据（根据身份证地区码 → 企业地区）
     */
    List<Map<String, Object>> getTalentFlow();

    /**
     * 获取大屏 KPI 汇总数据（公开接口，无需鉴权）
     */
    Map<String, Object> getScreenSummary(String range);

    /**
     * 获取投递转化漏斗数据（按状态分组统计）
     */
    Map<String, Object> getApplicationFunnel();

    /**
     * 获取企业审核 + 实名认证统计
     */
    Map<String, Object> getEnterpriseSummary();

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
