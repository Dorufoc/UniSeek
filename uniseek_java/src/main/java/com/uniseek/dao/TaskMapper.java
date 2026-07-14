package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.uniseek.dto.TaskSearchRequest;
import com.uniseek.dto.TaskVO;
import com.uniseek.entity.Task;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 职位任务 Mapper
 */
@Mapper
public interface TaskMapper extends BaseMapper<Task> {

    /**
     * 分页条件搜索职位
     *
     * @param page  MyBatis-Plus 分页对象
     * @param req   搜索条件
     * @return 分页结果
     */
    IPage<TaskVO> selectPageByCondition(Page<TaskVO> page, @Param("req") TaskSearchRequest req);

    /**
     * 查询职位详情（含是否已投递标记）
     *
     * @param id     职位 ID
     * @param userId 当前用户 ID
     * @return 职位详情 VO
     */
    TaskVO selectDetailById(@Param("id") Long id, @Param("userId") Long userId);

    /**
     * 查询本企业所有职位
     *
     * @param enterpriseId 企业 ID
     * @return 职位列表
     */
    List<TaskVO> selectEnterpriseTasks(@Param("enterpriseId") Long enterpriseId);
}
