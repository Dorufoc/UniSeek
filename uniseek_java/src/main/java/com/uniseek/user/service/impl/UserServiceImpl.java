package com.uniseek.user.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.uniseek.auth.dto.UserVO;
import com.uniseek.common.ApiResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.UserMapper;
import com.uniseek.entity.User;
import com.uniseek.user.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 用户服务实现
 */
@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserMapper userMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UserVO updateProfile(Long userId, String nickname, String avatarUrl, String phone, String email) {
        // 1. 校验用户是否存在
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }

        // 2. 如果修改手机号，检查唯一性
        if (phone != null && !phone.trim().isEmpty() && !phone.equals(user.getPhone())) {
            Integer phoneCount = userMapper.selectCount(
                    new LambdaQueryWrapper<User>()
                            .ne(User::getId, userId)
                            .eq(User::getPhone, phone.trim()));
            if (phoneCount > 0) {
                throw new BusinessException(ApiResult.CONFLICT, "该手机号已被其他账号绑定");
            }
        }

        // 3. 如果修改邮箱，检查唯一性
        if (email != null && !email.trim().isEmpty() && !email.equals(user.getEmail())) {
            Integer emailCount = userMapper.selectCount(
                    new LambdaQueryWrapper<User>()
                            .ne(User::getId, userId)
                            .eq(User::getEmail, email.trim()));
            if (emailCount > 0) {
                throw new BusinessException(ApiResult.CONFLICT, "该邮箱已被其他账号绑定");
            }
        }

        // 4. 构建更新条件——只更新非 null 的字段
        UpdateWrapper<User> uw = new UpdateWrapper<>();
        uw.eq("id", userId);

        boolean needUpdate = false;

        if (nickname != null && !nickname.trim().isEmpty()) {
            uw.set("nickname", nickname.trim());
            needUpdate = true;
        }
        if (avatarUrl != null && !avatarUrl.trim().isEmpty()) {
            uw.set("avatar_url", avatarUrl.trim());
            needUpdate = true;
        }
        if (phone != null && !phone.trim().isEmpty() && !phone.equals(user.getPhone())) {
            uw.set("phone", phone.trim());
            needUpdate = true;
        }
        if (email != null && !email.trim().isEmpty() && !email.equals(user.getEmail())) {
            uw.set("email", email.trim());
            needUpdate = true;
        }

        if (needUpdate) {
            uw.set("update_time", LocalDateTime.now());
            userMapper.update(null, uw);
            user = userMapper.selectById(userId);
        }

        // 5. 构建并返回脱敏 VO
        return buildUserVO(user);
    }

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
