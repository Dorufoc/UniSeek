package com.uniseek.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.common.util.UserContext;
import com.uniseek.entity.Task;
import com.uniseek.service.FavoriteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/favorites")
public class FavoriteController {

    @Autowired
    private FavoriteService favoriteService;

    @PostMapping("/{taskId}")
    public ApiResult<Map<String, Object>> addFavorite(@PathVariable Long taskId) {
        Long userId = UserContext.getUserId();
        favoriteService.addFavorite(userId, taskId);
        Map<String, Object> data = new HashMap<>();
        data.put("taskId", taskId);
        return ApiResult.success("收藏成功", data);
    }

    @DeleteMapping("/{taskId}")
    public ApiResult<Map<String, Object>> removeFavorite(@PathVariable Long taskId) {
        Long userId = UserContext.getUserId();
        favoriteService.removeFavorite(userId, taskId);
        Map<String, Object> data = new HashMap<>();
        data.put("taskId", taskId);
        return ApiResult.success("已取消收藏", data);
    }

    @GetMapping("/check/{taskId}")
    public ApiResult<Map<String, Object>> checkFavorited(@PathVariable Long taskId) {
        Long userId = UserContext.getUserId();
        boolean favorited = favoriteService.isFavorited(userId, taskId);
        Map<String, Object> data = new HashMap<>();
        data.put("favorited", favorited);
        return ApiResult.success(data);
    }

    @GetMapping
    public ApiResult<PageResult<Task>> listFavorites(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        Long userId = UserContext.getUserId();
        PageResult<Task> result = favoriteService.listFavorites(userId, page, pageSize);
        return ApiResult.success(result);
    }

    @GetMapping("/count")
    public ApiResult<Map<String, Object>> countFavorites() {
        Long userId = UserContext.getUserId();
        long count = favoriteService.countFavorites(userId);
        Map<String, Object> data = new HashMap<>();
        data.put("count", count);
        return ApiResult.success(data);
    }
}
