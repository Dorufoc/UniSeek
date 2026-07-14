package com.uniseek.constant;

/**
 * 操作类型常量类
 * <p>
 * 定义了系统中所有操作日志的操作类型常量，
 * 对应 {@link com.uniseek.entity.OperationLog#operationType} 字段的取值。
 * </p>
 */
public final class OperationType {

    /** 用户注册 */
    public static final String USER_REGISTER = "USER_REGISTER";

    /** 用户登录 */
    public static final String USER_LOGIN = "USER_LOGIN";

    /** 企业提交 */
    public static final String ENTERPRISE_SUBMIT = "ENTERPRISE_SUBMIT";

    /** 企业审核 */
    public static final String ENTERPRISE_AUDIT = "ENTERPRISE_AUDIT";

    /** 任务发布 */
    public static final String TASK_PUBLISH = "TASK_PUBLISH";

    /** 任务审核 */
    public static final String TASK_AUDIT = "TASK_AUDIT";

    /** 任务下线 */
    public static final String TASK_OFFLINE = "TASK_OFFLINE";

    /** 投递简历 */
    public static final String APPLICATION_DELIVER = "APPLICATION_DELIVER";

    /** 发送面试邀请 */
    public static final String APPLICATION_INTERVIEW = "APPLICATION_INTERVIEW";

    /** 标记为待定 */
    public static final String APPLICATION_PENDING = "APPLICATION_PENDING";

    /** 录用 */
    public static final String APPLICATION_HIRE = "APPLICATION_HIRE";

    /** 淘汰/拒绝 */
    public static final String APPLICATION_REJECT = "APPLICATION_REJECT";

    /** 结算完成 */
    public static final String APPLICATION_COMPLETE = "APPLICATION_COMPLETE";

    /** 投诉处理 */
    public static final String COMPLAINT_HANDLE = "COMPLAINT_HANDLE";

    /** 实名认证 */
    public static final String REAL_NAME_AUTH = "REAL_NAME_AUTH";

    private OperationType() {
        // 禁止实例化
    }
}
