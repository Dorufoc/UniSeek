package com.uniseek.controller;

import com.uniseek.auth.dto.*;
import com.uniseek.auth.dto.UpdatePhoneRequest;
import com.uniseek.auth.dto.UpdateEmailRequest;
import com.uniseek.auth.service.AuthService;
import com.uniseek.common.ApiResult;
import com.uniseek.common.util.UserContext;
import com.uniseek.operationlog.annotation.OperationLog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.Map;

/**
 * 认证控制器
 */
@RestController
@RequestMapping("/api/auth")
@Validated
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private AuthService authService;

    /**
     * 用户注册
     * POST /api/auth/register（无需鉴权）
     */
    @OperationLog(operationType = "REGISTER", targetType = "USER")
    @PostMapping("/register")
    public ApiResult<Map<String, Object>> register(@Valid @RequestBody RegisterRequest request) {
        Map<String, Object> data = authService.register(request);
        return ApiResult.success("注册成功", data);
    }

    /**
     * 用户登录
     * POST /api/auth/login（无需鉴权）
     */
    @OperationLog(operationType = "LOGIN", targetType = "USER")
    @PostMapping("/login")
    public ApiResult<Map<String, Object>> login(@Valid @RequestBody LoginRequest request) {
        Map<String, Object> data = authService.login(request);
        return ApiResult.success("登录成功", data);
    }

    /**
     * 退出登录
     * POST /api/auth/logout（需要鉴权）
     */
    @OperationLog(operationType = "LOGOUT", targetType = "USER")
    @PostMapping("/logout")
    public ApiResult<Void> logout() {
        Long userId = UserContext.getUserId();
        log.info("用户退出登录，userId: {}", userId);
        authService.logout(userId);
        UserContext.clear();
        return ApiResult.success("退出成功", null);
    }

    /**
     * 获取当前用户信息
     * GET /api/auth/current-user（需要鉴权）
     */
    @GetMapping("/current-user")
    public ApiResult<UserVO> getCurrentUser() {
        Long userId = UserContext.getUserId();
        UserVO userVO = authService.getCurrentUser(userId);
        return ApiResult.success(userVO);
    }

    /**
     * 修改密码
     * PUT /api/auth/password（需要鉴权）
     */
    @OperationLog(operationType = "CHANGE_PASSWORD", targetType = "USER")
    @PutMapping("/password")
    public ApiResult<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        Long userId = UserContext.getUserId();
        authService.changePassword(userId, request);
        return ApiResult.success("密码修改成功", null);
    }

    /**
     * 实名认证
     * POST /api/auth/real-name（需要鉴权）
     */
    @OperationLog(operationType = "REAL_NAME_AUTH", targetType = "USER")
    @PostMapping("/real-name")
    public ApiResult<RealNameAuthVO> realNameAuth(@Valid @RequestBody RealNameAuthRequest request) {
        Long userId = UserContext.getUserId();
        RealNameAuthVO vo = authService.realNameAuth(userId, request);
        return ApiResult.success("实名认证成功", vo);
    }

    /**
     * 获取实名认证状态
     * GET /api/auth/real-name/status（需要鉴权）
     */
    @GetMapping("/real-name/status")
    public ApiResult<Map<String, Object>> getRealNameStatus() {
        Long userId = UserContext.getUserId();
        Map<String, Object> data = authService.getRealNameStatus(userId);
        return ApiResult.success(data);
    }

    /**
     * 修改手机号
     * PUT /api/auth/phone（需要鉴权）
     */
    @OperationLog(operationType = "UPDATE_PHONE", targetType = "USER")
    @PutMapping("/phone")
    public ApiResult<Void> updatePhone(@Valid @RequestBody UpdatePhoneRequest request) {
        Long userId = UserContext.getUserId();
        authService.updatePhone(userId, request);
        return ApiResult.success("手机号修改成功", null);
    }

    /**
     * 修改邮箱
     * PUT /api/auth/email（需要鉴权）
     */
    @OperationLog(operationType = "UPDATE_EMAIL", targetType = "USER")
    @PutMapping("/email")
    public ApiResult<Void> updateEmail(@Valid @RequestBody UpdateEmailRequest request) {
        Long userId = UserContext.getUserId();
        authService.updateEmail(userId, request);
        return ApiResult.success("邮箱修改成功", null);
    }
}
