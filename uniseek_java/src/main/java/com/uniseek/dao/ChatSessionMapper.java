package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.uniseek.dto.ChatSessionVO;
import com.uniseek.entity.ChatSession;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 聊天会话 Mapper
 */
@Mapper
public interface ChatSessionMapper extends BaseMapper<ChatSession> {

    /**
     * 查询 HR 的聊天会话列表（关联职位信息、求职者信息、未读数）
     *
     * @param userId HR 用户 ID
     * @return 会话 VO 列表
     */
    List<ChatSessionVO> selectSessionsByEmployer(@Param("userId") Long userId);

    /**
     * 查询求职者的聊天会话列表（关联职位信息、企业 HR 信息、未读数）
     *
     * @param userId 求职者用户 ID
     * @return 会话 VO 列表
     */
    List<ChatSessionVO> selectSessionsBySeeker(@Param("userId") Long userId);

    /**
     * 查询单条会话详情
     *
     * @param applicationId 投递记录 ID
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @return 会话 VO
     */
    ChatSessionVO selectSessionDetail(@Param("applicationId") Long applicationId,
                                      @Param("userId") Long userId,
                                      @Param("role") Integer role);

    /**
     * 根据投递记录 ID 查询会话 ID
     *
     * @param applicationId 投递记录 ID
     * @return 会话 ID
     */
    Long selectIdByApplicationId(@Param("applicationId") Long applicationId);

    /**
     * 查找 HR 与求职者之间的直接会话（无投递记录关联）
     *
     * @param employerId HR 用户 ID
     * @param seekerId   求职者用户 ID
     * @return 会话 ID（不存在返回 null）
     */
    Long selectDirectSessionId(@Param("employerId") Long employerId, @Param("seekerId") Long seekerId);

    /**
     * 查询 HR 的直接会话列表（无投递关联的会话）
     *
     * @param userId HR 用户 ID
     * @return 会话 VO 列表
     */
    List<ChatSessionVO> selectDirectSessionsByEmployer(@Param("userId") Long userId);

    /**
     * 查询求职者的直接会话列表（无投递关联的会话）
     *
     * @param userId 求职者用户 ID
     * @return 会话 VO 列表
     */
    List<ChatSessionVO> selectDirectSessionsBySeeker(@Param("userId") Long userId);
}