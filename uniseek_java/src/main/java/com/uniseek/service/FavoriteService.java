package com.uniseek.service;

import com.uniseek.entity.Task;
import com.uniseek.common.PageResult;

import java.util.List;

public interface FavoriteService {

    void addFavorite(Long userId, Long taskId);

    void removeFavorite(Long userId, Long taskId);

    boolean isFavorited(Long userId, Long taskId);

    PageResult<Task> listFavorites(Long userId, int page, int pageSize);

    long countFavorites(Long userId);
}
