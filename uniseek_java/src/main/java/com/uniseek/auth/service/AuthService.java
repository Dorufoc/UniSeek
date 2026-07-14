package com.uniseek.auth.service;

import com.uniseek.auth.dto.*;

import java.util.Map;

/**
 * 认证服务接口
 */
public interface AuthService {

    /**
     * 用户注册
     *
     * @param request 注册请求
     * @return 包含 token 和 UserVO 的 Map
     */
    Map<String, Object> register(RegisterRequest request);

    /**
     * 用户登录
     *
     * @param request 登录请求
     * @return 包含 token 和 UserVO 的 Map
     */
    Map<String, Object> login(LoginRequest request);

    /**
     * 退出登录（记录日志）
     *
     * @param userId 当前用户 ID
     */
    void logout(Long userId);

    /**
     * 获取当前用户信息
     *
     * @param userId 用户 ID
     * @return 用户信息 VO
     */
    UserVO getCurrentUser(Long userId);

    /**
     * 修改密码
     *
     * @param userId  当前用户 ID
     * @param request 修改密码请求
     */
    void changePassword(Long userId, ChangePasswordRequest request);

    /**
     * 实名认证
     *
     * @param userId  当前用户 ID
     * @param request 实名认证请求
     * @return 实名认证信息 VO
     */
    RealNameAuthVO realNameAuth(Long userId, RealNameAuthRequest request);

    /**
     * 获取实名认证状态
     *
     * @param userId 当前用户 ID
     * @return 包含 isAuth、realName、idCard 的 Map
     */
    Map<String, Object> getRealNameStatus(Long userId);

    /**
     * 修改手机号
     *
     * @param userId  当前用户 ID
     * @param request 修改手机号请求
     */
    void updatePhone(Long userId, UpdatePhoneRequest request);

    /**
     * 修改邮箱
     *
     * @param userId  当前用户 ID
     * @param request 修改邮箱请求
     */
    void updateEmail(Long userId, UpdateEmailRequest request);
}
