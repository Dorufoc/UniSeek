package com.uniseek.config;

import com.uniseek.common.util.UserContext;
import com.uniseek.util.JwtUtil;
import io.jsonwebtoken.Claims;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.Arrays;
import java.util.List;

/**
 * JWT 鉴权拦截器
 */
@Component
public class JwtAuthInterceptor extends HandlerInterceptorAdapter {

    @Autowired
    private JwtUtil jwtUtil;

    /** 白名单路径 */
    private static final List<String> WHITE_LIST = Arrays.asList(
            "/api/auth/register",
            "/api/auth/login",
            "/api/region/"
    );

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) throws Exception {
        // 白名单放行
        String requestUri = request.getRequestURI();
        for (String whitePath : WHITE_LIST) {
            if (requestUri.startsWith(whitePath)) {
                return true;
            }
        }

        // 从 Authorization 头提取 Bearer token
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":401,\"message\":\"未提供有效的认证令牌\"}");
            return false;
        }

        String token = authHeader.substring(7);

        // 验证 Token
        if (!jwtUtil.validateToken(token)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":401,\"message\":\"认证令牌无效或已过期\"}");
            return false;
        }

        // 解析用户信息并存入上下文
        Claims claims = jwtUtil.parseToken(token);
        Long userId = claims.get("userId", Long.class);
        Integer role = claims.get("role", Integer.class);
        UserContext.set(userId, role);

        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) throws Exception {
        // 请求结束后清理上下文
        UserContext.clear();
    }
}
