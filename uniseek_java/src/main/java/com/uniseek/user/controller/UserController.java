package com.uniseek.user.controller;

import com.uniseek.auth.dto.UserVO;
import com.uniseek.common.ApiResult;
import com.uniseek.common.util.UserContext;
import com.uniseek.user.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户控制器——处理用户资料相关请求
 */
@RestController
@RequestMapping("/api/user")
public class UserController {

    @Autowired
    private UserService userService;

    /**
     * 更新用户资料（昵称、头像）
     *
     * @param nickname  新昵称（可选）
     * @param avatarUrl 新头像 URL（可选）
     * @return 更新结果
     */
    @PutMapping("/profile")
    public ApiResult<UserVO> updateProfile(
            @RequestParam(required = false) String nickname,
            @RequestParam(required = false) String avatarUrl) {

        Long userId = UserContext.getUserId();
        UserVO userVO = userService.updateProfile(userId, nickname, avatarUrl);
        return ApiResult.success("更新成功", userVO);
    }
}
