package com.uniseek.auth.service.impl;

import com.uniseek.auth.dto.RealNameAuthRequest;
import com.uniseek.auth.dto.RealNameAuthVO;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.RealNameAuthMapper;
import com.uniseek.entity.RealNameAuth;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class AuthServiceImplTest {

    private static final String VALID_ID_CARD = "610423196510085516";

    @Mock
    private RealNameAuthMapper realNameAuthMapper;

    private AuthServiceImpl authService;

    @Before
    public void setUp() {
        authService = new AuthServiceImpl();
        ReflectionTestUtils.setField(authService, "realNameAuthMapper", realNameAuthMapper);
    }

    @Test
    public void shouldUpdatePendingAuthInsteadOfInsertingDuplicateUserId() {
        RealNameAuth pendingAuth = new RealNameAuth();
        pendingAuth.setId(12L);
        pendingAuth.setUserId(7L);
        pendingAuth.setStatus(0);
        when(realNameAuthMapper.selectOne(any())).thenReturn(pendingAuth, null);

        RealNameAuthVO result = authService.realNameAuth(7L, request("张三", VALID_ID_CARD));

        assertEquals("张三", result.getRealName());
        assertEquals(1, pendingAuth.getStatus().intValue());
        assertEquals(VALID_ID_CARD, pendingAuth.getIdCard());
        verify(realNameAuthMapper).updateById(pendingAuth);
        verify(realNameAuthMapper, never()).insert(any(RealNameAuth.class));
    }

    @Test
    public void shouldRejectIdCardUsedByAnotherUserBeforeInsert() {
        RealNameAuth anotherUserAuth = new RealNameAuth();
        anotherUserAuth.setId(21L);
        anotherUserAuth.setUserId(8L);
        anotherUserAuth.setIdCard(VALID_ID_CARD);
        when(realNameAuthMapper.selectOne(any())).thenReturn(null, anotherUserAuth);

        try {
            authService.realNameAuth(7L, request("张三", VALID_ID_CARD));
        } catch (BusinessException exception) {
            assertEquals(409, exception.getCode());
            assertEquals("该身份证号已被其他用户使用", exception.getMessage());
            verify(realNameAuthMapper, never()).insert(any(RealNameAuth.class));
            return;
        }

        throw new AssertionError("应在插入前拒绝已被其他用户使用的身份证号");
    }

    private RealNameAuthRequest request(String realName, String idCard) {
        RealNameAuthRequest request = new RealNameAuthRequest();
        request.setRealName(realName);
        request.setIdCard(idCard);
        return request;
    }
}
