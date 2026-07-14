package com.uniseek.operationlog.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 操作日志注解 —— 标注在 Controller 方法上，由切面自动记录操作日志
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface OperationLog {

    /**
     * 操作类型，例如 REGISTER、LOGIN、SAVE_RESUME 等
     */
    String operationType();

    /**
     * 目标类型，例如 USER、RESUME、TASK 等
     */
    String targetType();
}
