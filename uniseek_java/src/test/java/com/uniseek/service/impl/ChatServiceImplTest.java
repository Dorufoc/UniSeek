package com.uniseek.service.impl;

import com.uniseek.chat.ChatSessionType;
import com.uniseek.common.ApiResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.ChatMessageMapper;
import com.uniseek.dao.ChatSessionMapper;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.ResumeMapper;
import com.uniseek.dao.TaskApplicationMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.dao.UserMapper;
import com.uniseek.dto.ChatSessionVO;
import com.uniseek.entity.ChatSession;
import com.uniseek.entity.User;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * ChatServiceImpl 回归测试：验证 sessionType 显式判别器可解决 chat_session.id 与 task_application.id 冲突
 */
@RunWith(MockitoJUnitRunner.class)
public class ChatServiceImplTest {

    @Mock
    private ChatSessionMapper chatSessionMapper;

    @Mock
    private ChatMessageMapper chatMessageMapper;

    @Mock
    private TaskApplicationMapper taskApplicationMapper;

    @Mock
    private TaskMapper taskMapper;

    @Mock
    private EnterpriseMapper enterpriseMapper;

    @Mock
    private UserMapper userMapper;

    @Mock
    private ResumeMapper resumeMapper;

    private ChatServiceImpl chatService;

    @Before
    public void setUp() {
        chatService = new ChatServiceImpl();
        ReflectionTestUtils.setField(chatService, "chatSessionMapper", chatSessionMapper);
        ReflectionTestUtils.setField(chatService, "chatMessageMapper", chatMessageMapper);
        ReflectionTestUtils.setField(chatService, "taskApplicationMapper", taskApplicationMapper);
        ReflectionTestUtils.setField(chatService, "taskMapper", taskMapper);
        ReflectionTestUtils.setField(chatService, "enterpriseMapper", enterpriseMapper);
        ReflectionTestUtils.setField(chatService, "userMapper", userMapper);
        ReflectionTestUtils.setField(chatService, "resumeMapper", resumeMapper);
    }

    @Test
    public void getSessionDetail_whenSessionTypeDirect_shouldResolveByChatSessionIdAndNotQueryApplicationId() {
        // 构造直接会话：id 与某个 task_application.id 相同，但 task_application_id 为 null
        ChatSession directSession = new ChatSession();
        directSession.setId(5L);
        directSession.setTaskApplicationId(null);
        directSession.setEmployerId(20L);
        directSession.setSeekerId(10L);
        when(chatSessionMapper.selectById(5L)).thenReturn(directSession);

        User employer = new User();
        employer.setId(20L);
        employer.setNickname("HR");
        when(userMapper.selectById(20L)).thenReturn(employer);

        ChatSessionVO vo = chatService.getSessionDetail(5L, 10L, 0, ChatSessionType.DIRECT);

        assertNotNull(vo);
        assertEquals(Long.valueOf(5L), vo.getApplicationId());
        assertEquals(ChatSessionType.DIRECT, vo.getSessionType());
        assertEquals(Long.valueOf(20L), vo.getCounterpartId());
        assertEquals("HR", vo.getCounterpartName());
        assertEquals(Boolean.TRUE, vo.getCanSend());
        // 关键回归点：direct 场景绝不允许通过 task_application_id 解析，防止与投递 ID 冲突
        verify(chatSessionMapper, never()).selectSessionDetail(any(), any(), any());
        verify(chatSessionMapper, never()).selectIdByApplicationId(any());
    }

    @Test
    public void getSessionDetail_whenSessionTypeDirectAndUserNotParticipant_shouldThrowForbidden() {
        ChatSession directSession = new ChatSession();
        directSession.setId(5L);
        directSession.setTaskApplicationId(null);
        directSession.setEmployerId(20L);
        directSession.setSeekerId(10L);
        when(chatSessionMapper.selectById(5L)).thenReturn(directSession);

        try {
            chatService.getSessionDetail(5L, 30L, 0, ChatSessionType.DIRECT);
        } catch (BusinessException e) {
            assertEquals(ApiResult.FORBIDDEN, e.getCode());
            assertEquals("无权访问该会话", e.getMessage());
            verify(chatSessionMapper, never()).selectSessionDetail(any(), any(), any());
            verify(chatSessionMapper, never()).selectIdByApplicationId(any());
            return;
        }

        throw new AssertionError("非参与者访问直接会话时应抛出无权限异常");
    }

    @Test
    public void getSessionDetail_whenApplicationSessionType_shouldResolveByApplicationId() {
        // 投递会话：传入的是 task_application_id，service 需解析到真实 chat_session.id
        ChatSessionVO applicationVo = new ChatSessionVO();
        applicationVo.setApplicationId(5L);
        applicationVo.setCounterpartId(10L);
        applicationVo.setCounterpartName("求职者");
        when(chatSessionMapper.selectSessionDetail(5L, 20L, 1)).thenReturn(applicationVo);

        ChatSession realSession = new ChatSession();
        realSession.setId(100L);
        realSession.setSeekerId(10L);
        realSession.setEmployerId(20L);
        when(chatSessionMapper.selectIdByApplicationId(5L)).thenReturn(100L);
        when(chatSessionMapper.selectById(100L)).thenReturn(realSession);

        ChatSessionVO vo = chatService.getSessionDetail(5L, 20L, 1, ChatSessionType.APPLICATION);

        assertNotNull(vo);
        assertEquals(ChatSessionType.APPLICATION, vo.getSessionType());
        assertEquals("求职者", vo.getCounterpartName());
        // 确保按 task_application_id 解析到真实会话 ID，而不是把 5L 当成 chat_session.id
        verify(chatSessionMapper).selectById(100L);
        verify(chatSessionMapper, never()).selectById(5L);
    }

    @Test
    public void getSessionDetail_whenSessionTypeAbsentAndNoApplicationSession_shouldThrowNotFoundWithoutDirectFallback() {
        // sessionType 缺省时默认按 application 处理，若不存在对应投递会话，不允许回退到直接会话
        when(chatSessionMapper.selectSessionDetail(5L, 20L, 1)).thenReturn(null);

        try {
            chatService.getSessionDetail(5L, 20L, 1, null);
        } catch (BusinessException e) {
            assertEquals(ApiResult.NOT_FOUND, e.getCode());
            assertEquals("会话不存在", e.getMessage());
            // 关键回归点：application 路径不再回退到 chat_session.id，避免 ID 冲突
            verify(chatSessionMapper, never()).selectById(5L);
            return;
        }

        throw new AssertionError("投递会话不存在时不应回退到直接会话");
    }
}
