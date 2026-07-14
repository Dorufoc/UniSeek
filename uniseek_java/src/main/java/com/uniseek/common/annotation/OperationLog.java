package com.uniseek.common.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 操作日志注解（占位，在 Todo 15 中实现 AOP 处理逻辑）
 * <p>
 * 标注在 Controller 或 Service 方法上，用于记录操作日志。
 * 当前仅做标记，后续将通过 AOP 切面实现日志记录。
 * </p>
 */
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface OperationLog {

    /**
     * 操作模块
     */
    String module() default "";

    /**
     * 操作类型（如：提交、更新、删除）
     */
    String action() default "";

    /**
     * 操作描述
     */
    String description() default "";
}
