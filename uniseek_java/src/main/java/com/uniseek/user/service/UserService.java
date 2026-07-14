package com.uniseek.user.service;

import com.uniseek.auth.dto.UserVO;

/**
 * 用户服务接口
 */
public interface UserService {

    /**
     * 更新用户资料（昵称、头像）
     *
     * @param userId    用户 ID
     * @param nickname  新昵称（可选，为 null 则不更新）
     * @param avatarUrl 新头像 URL（可选，为 null 则不更新）
     * @return 脱敏后的用户信息 VO
     */
    UserVO updateProfile(Long userId, String nickname, String avatarUrl);
}
