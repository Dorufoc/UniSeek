package com.uniseek.user.service.impl;

import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.uniseek.auth.dto.UserVO;
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
    public UserVO updateProfile(Long userId, String nickname, String avatarUrl) {
        // 1. 校验用户是否存在
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }

        // 2. 构建更新条件——只更新非 null 的字段
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

        if (needUpdate) {
            uw.set("update_time", LocalDateTime.now());
            userMapper.update(null, uw);

            // 重新查询最新数据
            user = userMapper.selectById(userId);
        }

        // 3. 构建并返回脱敏 VO
        return buildUserVO(user);
    }

    /**
     * 构建 UserVO（带脱敏处理）
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
