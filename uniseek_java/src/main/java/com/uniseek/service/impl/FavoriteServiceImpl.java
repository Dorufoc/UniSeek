package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.uniseek.common.PageResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.FavoriteMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.entity.Favorite;
import com.uniseek.entity.Task;
import com.uniseek.service.FavoriteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class FavoriteServiceImpl implements FavoriteService {

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Autowired
    private TaskMapper taskMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void addFavorite(Long userId, Long taskId) {
        QueryWrapper<Favorite> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId).eq("task_id", taskId);
        if (favoriteMapper.selectCount(wrapper) > 0) {
            throw new BusinessException("已收藏过该职位");
        }
        Task task = taskMapper.selectById(taskId);
        if (task == null) {
            throw new BusinessException("职位不存在");
        }
        Favorite favorite = new Favorite();
        favorite.setUserId(userId);
        favorite.setTaskId(taskId);
        favorite.setCreateTime(LocalDateTime.now());
        favoriteMapper.insert(favorite);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeFavorite(Long userId, Long taskId) {
        QueryWrapper<Favorite> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId).eq("task_id", taskId);
        if (favoriteMapper.delete(wrapper) == 0) {
            throw new BusinessException("未收藏该职位");
        }
    }

    @Override
    public boolean isFavorited(Long userId, Long taskId) {
        QueryWrapper<Favorite> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId).eq("task_id", taskId);
        return favoriteMapper.selectCount(wrapper) > 0;
    }

    @Override
    public PageResult<Task> listFavorites(Long userId, int page, int pageSize) {
        QueryWrapper<Favorite> favWrapper = new QueryWrapper<>();
        favWrapper.eq("user_id", userId).orderByDesc("create_time");
        IPage<Favorite> favPage = favoriteMapper.selectPage(new Page<>(page, pageSize), favWrapper);

        List<Long> taskIds = favPage.getRecords().stream()
                .map(Favorite::getTaskId)
                .collect(Collectors.toList());

        List<Task> tasks = taskIds.isEmpty()
                ? java.util.Collections.emptyList()
                : taskMapper.selectBatchIds(taskIds);

        PageResult<Task> result = new PageResult<>();
        result.setRecords(tasks);
        result.setTotal(favPage.getTotal());
        result.setPage((int) favPage.getCurrent());
        result.setPageSize((int) favPage.getSize());
        return result;
    }

    @Override
    public long countFavorites(Long userId) {
        QueryWrapper<Favorite> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId);
        return favoriteMapper.selectCount(wrapper);
    }
}
