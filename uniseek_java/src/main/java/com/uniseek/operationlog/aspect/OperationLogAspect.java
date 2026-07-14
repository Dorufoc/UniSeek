package com.uniseek.operationlog.aspect;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uniseek.common.util.UserContext;
import com.uniseek.operationlog.annotation.OperationLog;
import com.uniseek.service.OperationLogService;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.DefaultParameterNameDiscoverer;
import org.springframework.core.ParameterNameDiscoverer;
import org.springframework.expression.EvaluationContext;
import org.springframework.expression.Expression;
import org.springframework.expression.ExpressionParser;
import org.springframework.expression.spel.standard.SpelExpressionParser;
import org.springframework.expression.spel.support.StandardEvaluationContext;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 操作日志切面 —— 在标注 @OperationLog 的方法执行后自动记录操作日志
 */
@Aspect
@Component
public class OperationLogAspect {

    private static final Logger log = LoggerFactory.getLogger(OperationLogAspect.class);

    @Autowired
    private OperationLogService operationLogService;

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * 环绕通知：方法执行完毕后记录操作日志
     */
    @Around("@annotation(operationLog)")
    public Object around(ProceedingJoinPoint joinPoint, OperationLog operationLog) throws Throwable {
        // 先执行原方法
        Object result = joinPoint.proceed();

        try {
            // 获取方法参数名和参数值
            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            String[] paramNames = signature.getParameterNames();
            Object[] paramValues = joinPoint.getArgs();

            // 构建 detail JSON（方法参数）
            Map<String, Object> detailMap = new HashMap<>();
            if (paramNames != null) {
                for (int i = 0; i < paramNames.length; i++) {
                    // 跳过 HttpServletRequest、HttpServletResponse 等 Servlet 对象，避免序列化异常
                    Object value = paramValues[i];
                    if (value instanceof HttpServletRequest) {
                        continue;
                    }
                    detailMap.put(paramNames[i], value);
                }
            }
            String detail = objectMapper.writeValueAsString(detailMap);

            // 获取客户端 IP
            String ipAddress = getClientIp();

            // 获取当前操作人 ID
            Long operatorId = UserContext.getUserId();

            // 创建操作日志并保存
            com.uniseek.entity.OperationLog logEntity = new com.uniseek.entity.OperationLog();
            logEntity.setOperatorId(operatorId);
            logEntity.setOperationType(operationLog.operationType());
            logEntity.setTargetType(operationLog.targetType());

            // 解析 SpEL 表达式获取 targetId
            String targetIdExpression = operationLog.targetIdExpression();
            if (targetIdExpression != null && !targetIdExpression.isEmpty()) {
                Long targetId = parseTargetId(targetIdExpression, signature, paramValues);
                logEntity.setTargetId(targetId);
            }

            logEntity.setDetail(detail);
            logEntity.setIpAddress(ipAddress);
            logEntity.setCreateTime(LocalDateTime.now());

            operationLogService.saveLog(logEntity);
        } catch (Exception e) {
            // 日志记录失败不应影响主流程
            log.error("记录操作日志异常", e);
        }

        return result;
    }

    /**
     * 解析 SpEL 表达式获取目标 ID
     */
    private Long parseTargetId(String expression, MethodSignature signature, Object[] args) {
        try {
            ExpressionParser parser = new SpelExpressionParser();
            Expression exp = parser.parseExpression(expression);
            EvaluationContext context = new StandardEvaluationContext();
            String[] paramNames = signature.getParameterNames();
            if (paramNames != null) {
                for (int i = 0; i < paramNames.length; i++) {
                    context.setVariable(paramNames[i], args[i]);
                }
            }
            Object value = exp.getValue(context);
            if (value instanceof Number) {
                return ((Number) value).longValue();
            }
            if (value instanceof String) {
                return Long.valueOf((String) value);
            }
        } catch (Exception e) {
            log.warn("解析 targetId SpEL 表达式失败: {}", expression, e);
        }
        return null;
    }

    /**
     * 从当前请求中获取客户端 IP 地址
     */
    private String getClientIp() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes != null) {
                HttpServletRequest request = attributes.getRequest();
                String ip = request.getRemoteAddr();
                // 代理环境下获取真实 IP
                String xForwardedFor = request.getHeader("X-Forwarded-For");
                if (xForwardedFor != null && !xForwardedFor.isEmpty() && !"unknown".equalsIgnoreCase(xForwardedFor)) {
                    ip = xForwardedFor.split(",")[0].trim();
                }
                return ip;
            }
        } catch (Exception e) {
            log.warn("获取客户端 IP 失败", e);
        }
        return "unknown";
    }
}
