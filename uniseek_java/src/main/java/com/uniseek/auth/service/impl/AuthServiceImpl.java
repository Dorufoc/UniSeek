package com.uniseek.auth.service.impl;

import cn.hutool.core.util.IdcardUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.uniseek.auth.dto.*;
import com.uniseek.auth.service.AuthService;
import com.uniseek.common.ApiResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.RealNameAuthMapper;
import com.uniseek.dao.UserMapper;
import com.uniseek.entity.RealNameAuth;
import com.uniseek.entity.User;
import com.uniseek.entity.OperationLog;
import com.uniseek.service.OperationLogService;
import com.uniseek.util.JwtUtil;
import com.uniseek.util.PasswordUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 认证服务实现
 */
@Service
public class AuthServiceImpl implements AuthService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private RealNameAuthMapper realNameAuthMapper;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private OperationLogService operationLogService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> register(RegisterRequest request) {
        // 1. 校验手机号格式（第 3 位必须是 1-9 的数字）
        String phone = request.getPhone().trim();
        if (phone.length() != 11 || phone.charAt(2) < '1' || phone.charAt(2) > '9') {
            throw new BusinessException("手机号格式不正确");
        }

        // 2. 校验邮箱格式（@Email 注解已处理基础格式，此处可做额外校验）
        String email = request.getEmail().trim();
        if (!email.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")) {
            throw new BusinessException("邮箱格式不正确");
        }

        // 3. 校验手机号唯一性
        Integer phoneCount = userMapper.selectCount(
                new LambdaQueryWrapper<User>().eq(User::getPhone, phone));
        if (phoneCount > 0) {
            throw new BusinessException(ApiResult.CONFLICT, "该手机号已注册");
        }

        // 4. 校验邮箱唯一性
        Integer emailCount = userMapper.selectCount(
                new LambdaQueryWrapper<User>().eq(User::getEmail, email));
        if (emailCount > 0) {
            throw new BusinessException(ApiResult.CONFLICT, "该邮箱已被注册");
        }

        // 5. 校验密码长度和一致性
        String password = request.getPassword();
        if (password.length() < 6 || password.length() > 20) {
            throw new BusinessException("密码长度需为 6~20 位");
        }
        if (!password.equals(request.getConfirmPassword())) {
            throw new BusinessException("两次输入的密码不一致");
        }

        // 6. 生成盐值并加密密码
        String salt = PasswordUtil.generateSalt();
        String encryptedPassword = PasswordUtil.encryptPassword(password, salt);

        // 7. 构建用户实体
        User user = new User();
        user.setPhone(phone);
        user.setEmail(email);
        user.setPassword(encryptedPassword);
        user.setSalt(salt);
        user.setNickname(request.getNickname().trim());
        user.setRole(request.getRole());
        user.setStatus(1);
        user.setCreditScore(100);
        user.setCreateTime(LocalDateTime.now());
        user.setUpdateTime(LocalDateTime.now());

        // 8. 插入用户
        userMapper.insert(user);

        // 8b. 手动记录注册日志（register 接口无 JWT Token，AOP 无法获取操作人）
        try {
            OperationLog logEntity = new OperationLog();
            logEntity.setOperatorId(user.getId());
            logEntity.setOperationType("REGISTER");
            logEntity.setTargetType("USER");
            logEntity.setTargetId(user.getId());
            Map<String, Object> detail = new HashMap<>();
            detail.put("userId", user.getId());
            detail.put("role", user.getRole());
            logEntity.setDetail(objectMapper.writeValueAsString(detail));
            logEntity.setCreateTime(LocalDateTime.now());
            // 获取客户端 IP
            try {
                ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
                if (attrs != null) {
                    HttpServletRequest req = attrs.getRequest();
                    String ip = req.getHeader("X-Forwarded-For");
                    if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
                        ip = req.getHeader("X-Real-IP");
                    }
                    if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
                        ip = req.getRemoteAddr();
                    }
                    logEntity.setIpAddress(ip);
                }
            } catch (Exception ignored) {}
            operationLogService.saveLog(logEntity);
        } catch (Exception ignored) {
            // 日志记录失败不影响主流程
        }

        // 9. 生成 Token
        String token = jwtUtil.generateToken(user.getId(), user.getRole(), user.getPhone());

        // 10. 构建 UserVO（脱敏）
        UserVO userVO = buildUserVO(user);

        // 11. 返回结果
        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("userInfo", userVO);
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> login(LoginRequest request) {
        // 1. 根据账号查询用户（含 @ 符为邮箱登录，否则手机号登录）
        String account = request.getAccount().trim();
        boolean isEmail = account.contains("@");
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<User>()
                .eq(isEmail ? User::getEmail : User::getPhone, account);
        User user = userMapper.selectOne(wrapper);

        // 2. 用户不存在
        if (user == null) {
            throw new BusinessException("账号或密码错误");
        }

        // 3. 检查账号状态
        if (user.getStatus() == 0) {
            throw new BusinessException(ApiResult.FORBIDDEN, "账号已被禁用，请联系管理员");
        }

        // 4. 校验密码
        if (!PasswordUtil.verify(request.getPassword(), user.getPassword(), user.getSalt())) {
            throw new BusinessException("账号或密码错误");
        }

        // 5. 更新最后登录时间
        user.setLastLoginTime(LocalDateTime.now());
        userMapper.updateById(user);

        // 6. 记录登录操作日志（含正确操作人）
        try {
            Map<String, Object> detail = new HashMap<>();
            detail.put("userId", user.getId());
            detail.put("role", user.getRole());
            OperationLog logEntity = new OperationLog();
            logEntity.setOperatorId(user.getId());
            logEntity.setOperationType("LOGIN");
            logEntity.setTargetType("USER");
            logEntity.setTargetId(user.getId());
            logEntity.setDetail(objectMapper.writeValueAsString(detail));
            logEntity.setCreateTime(LocalDateTime.now());
            // 获取客户端 IP
            try {
                ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
                if (attrs != null) {
                    HttpServletRequest req = attrs.getRequest();
                    String ip = req.getHeader("X-Forwarded-For");
                    if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
                        ip = req.getHeader("X-Real-IP");
                    }
                    if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
                        ip = req.getRemoteAddr();
                    }
                    logEntity.setIpAddress(ip);
                }
            } catch (Exception ignored) {}
            operationLogService.saveLog(logEntity);
        } catch (Exception ignored) {
            // 日志记录失败不影响主流程
        }

        // 7. 生成 Token
        String token = jwtUtil.generateToken(user.getId(), user.getRole(), user.getPhone());

        // 8. 构建 UserVO（脱敏）
        UserVO userVO = buildUserVO(user);

        // 8. 返回结果
        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("userInfo", userVO);
        return result;
    }

    @Override
    public void logout(Long userId) {
        // 退出操作不再记录日志
    }

    @Override
    public UserVO getCurrentUser(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        return buildUserVO(user);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void changePassword(Long userId, ChangePasswordRequest request) {
        // 1. 查询用户
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }

        // 2. 校验旧密码
        if (!PasswordUtil.verify(request.getOldPassword(), user.getPassword(), user.getSalt())) {
            throw new BusinessException("原密码错误");
        }

        // 3. 校验新密码长度
        String newPassword = request.getNewPassword();
        if (newPassword.length() < 6 || newPassword.length() > 20) {
            throw new BusinessException("新密码长度需为 6~20 位");
        }

        // 4. 校验两次密码一致
        if (!newPassword.equals(request.getConfirmPassword())) {
            throw new BusinessException("两次输入的密码不一致");
        }

        // 5. 加密新密码并更新
        String encryptedPassword = PasswordUtil.encryptPassword(newPassword, user.getSalt());
        user.setPassword(encryptedPassword);
        user.setUpdateTime(LocalDateTime.now());
        userMapper.updateById(user);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public RealNameAuthVO realNameAuth(Long userId, RealNameAuthRequest request) {
        // 1. 查询该用户已有的实名认证记录
        RealNameAuth existingAuth = realNameAuthMapper.selectOne(
                new LambdaQueryWrapper<RealNameAuth>()
                        .eq(RealNameAuth::getUserId, userId));

        if (existingAuth != null && existingAuth.getStatus() != null && existingAuth.getStatus() == 1) {
            throw new BusinessException(ApiResult.CONFLICT, "您已完成实名认证，无需重复认证");
        }

        // 2. 校验身份证格式
        String idCard = request.getIdCard().trim();
        if (!IdcardUtil.isValidCard(idCard)) {
            throw new BusinessException("身份证号格式不正确");
        }

        // 3. 校验年龄（需满 16 周岁）
        int age = IdcardUtil.getAgeByIdCard(idCard);
        if (age < 16) {
            throw new BusinessException("未满16周岁，无法完成实名认证");
        }

        // 4. 防止身份证号被其他用户重复使用
        RealNameAuth idCardAuth = realNameAuthMapper.selectOne(
                new LambdaQueryWrapper<RealNameAuth>()
                        .eq(RealNameAuth::getIdCard, idCard));
        if (idCardAuth != null && !userId.equals(idCardAuth.getUserId())) {
            throw new BusinessException(ApiResult.CONFLICT, "该身份证号已被其他用户使用");
        }

        // 5. 已有未认证记录时更新，避免触发 user_id 唯一索引
        RealNameAuth auth = existingAuth == null ? new RealNameAuth() : existingAuth;
        auth.setUserId(userId);
        auth.setRealName(request.getRealName().trim());
        auth.setIdCard(idCard);
        auth.setStatus(1);
        auth.setAuthTime(LocalDateTime.now());
        auth.setUpdateTime(LocalDateTime.now());
        if (existingAuth == null) {
            auth.setCreateTime(LocalDateTime.now());
            realNameAuthMapper.insert(auth);
        } else {
            realNameAuthMapper.updateById(auth);
        }

        // 5. 构建返回值（身份证号脱敏）
        RealNameAuthVO vo = new RealNameAuthVO();
        vo.setRealName(auth.getRealName());
        vo.setIdCard(RealNameAuthVO.idCardDesensitization(auth.getIdCard()));
        vo.setAuthTime(auth.getAuthTime());
        return vo;
    }

    @Override
    public Map<String, Object> getRealNameStatus(Long userId) {
        Map<String, Object> result = new HashMap<>();
        RealNameAuth auth = realNameAuthMapper.selectOne(
                new LambdaQueryWrapper<RealNameAuth>()
                        .eq(RealNameAuth::getUserId, userId)
                        .eq(RealNameAuth::getStatus, 1));

        if (auth == null) {
            result.put("isAuth", false);
            result.put("realName", null);
            result.put("idCard", null);
            result.put("birthDate", null);
            result.put("gender", -1);
        } else {
            result.put("isAuth", true);
            result.put("realName", auth.getRealName());
            result.put("idCard", RealNameAuthVO.idCardDesensitization(auth.getIdCard()));

            // 从身份证号提取出生日期（yyyyMMdd → yyyy-MM-dd）
            String birthByIdCard = IdcardUtil.getBirthByIdCard(auth.getIdCard());
            if (birthByIdCard != null && birthByIdCard.length() == 8) {
                birthByIdCard = birthByIdCard.substring(0, 4) + "-"
                        + birthByIdCard.substring(4, 6) + "-"
                        + birthByIdCard.substring(6, 8);
            }
            result.put("birthDate", birthByIdCard);

            // Hutool getGenderByIdCard 返回: 1=男, 0=女, -1=未知
            // 前端: 0=男, 1=女, -1=未设置
            int genderFromCard = IdcardUtil.getGenderByIdCard(auth.getIdCard());
            if (genderFromCard == 1) {
                result.put("gender", 0); // 男
            } else if (genderFromCard == 0) {
                result.put("gender", 1); // 女
            } else {
                result.put("gender", -1);
            }
        }
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updatePhone(Long userId, UpdatePhoneRequest request) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        if (!PasswordUtil.verify(request.getPassword(), user.getPassword(), user.getSalt())) {
            throw new BusinessException("密码验证失败");
        }
        String newPhone = request.getNewPhone().trim();
        if (newPhone.length() != 11 || newPhone.charAt(2) < '1' || newPhone.charAt(2) > '9') {
            throw new BusinessException("手机号格式不正确");
        }
        Integer count = userMapper.selectCount(
                new LambdaQueryWrapper<User>().eq(User::getPhone, newPhone));
        if (count > 0) {
            throw new BusinessException(ApiResult.CONFLICT, "该手机号已被绑定");
        }
        user.setPhone(newPhone);
        user.setUpdateTime(LocalDateTime.now());
        userMapper.updateById(user);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateEmail(Long userId, UpdateEmailRequest request) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        if (!PasswordUtil.verify(request.getPassword(), user.getPassword(), user.getSalt())) {
            throw new BusinessException("密码验证失败");
        }
        String newEmail = request.getNewEmail().trim();
        if (!newEmail.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")) {
            throw new BusinessException("邮箱格式不正确");
        }
        Integer count = userMapper.selectCount(
                new LambdaQueryWrapper<User>().eq(User::getEmail, newEmail));
        if (count > 0) {
            throw new BusinessException(ApiResult.CONFLICT, "该邮箱已被绑定");
        }
        user.setEmail(newEmail);
        user.setUpdateTime(LocalDateTime.now());
        userMapper.updateById(user);
    }

    /**
     * 构建 UserVO（带脱敏处理）
     *
     * @param user 用户实体
     * @return 用户信息 VO
     */
    private UserVO buildUserVO(User user) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setPhone(UserVO.phoneDesensitization(user.getPhone()));
        vo.setEmail(UserVO.emailDesensitization(user.getEmail()));
        vo.setNickname(user.getNickname());
        vo.setAvatarUrl(user.getAvatarUrl());
        vo.setRole(user.getRole());
        vo.setStatus(user.getStatus());
        vo.setCreditScore(user.getCreditScore());
        vo.setLastLoginTime(user.getLastLoginTime());
        vo.setCreateTime(user.getCreateTime());
        return vo;
    }
}
