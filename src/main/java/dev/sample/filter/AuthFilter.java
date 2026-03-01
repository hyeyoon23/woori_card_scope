package dev.sample.filter;

import dev.sample.dto.*;
import dev.sample.dao.*;
import dev.sample.service.*;
import dev.sample.config.*;
import dev.sample.filter.*;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebFilter(urlPatterns = { "/customers/*", "/api/*", "/" })
public class AuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String path = req.getRequestURI();
        String contextPath = req.getContextPath();
        String relativePath = path.substring(contextPath.length());

        // 루트 경로는 /customers로 강제 리다이렉트
        if (relativePath.equals("/")) {
            resp.sendRedirect(contextPath + "/customers");
            return;
        }

        // 제외할 경로 (로그인, 회원가입, 정적 리소스)
        if (relativePath.startsWith("/login") || relativePath.startsWith("/signup") ||
                relativePath.startsWith("/css") || relativePath.startsWith("/js") ||
                relativePath.startsWith("/favicon")) {
            chain.doFilter(request, response);
            return;
        }

        // 인증 체크 (세션에 USER 객체가 있는지 확인)
        HttpSession session = req.getSession(false);
        boolean loggedIn = (session != null && session.getAttribute("USER") != null);

        if (loggedIn) {
            // 정상적으로 필터 통과
            chain.doFilter(request, response);
        } else {
            // 비로그인 시
            // AJAX/API 요청 처리 (api 폴더나 XMLHttpRequest)
            String ajaxHeader = req.getHeader("X-Requested-With");
            if ("XMLHttpRequest".equals(ajaxHeader) || relativePath.startsWith("/api/")) {
                resp.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
            } else {
                // 일반 페이지 요청의 경우 원래 가려던 경로를 세션에 저장
                if (session == null) {
                    session = req.getSession(true);
                }
                String queryString = req.getQueryString();
                String redirectUrl = path + (queryString != null ? "?" + queryString : "");
                session.setAttribute("REDIRECT_URL", redirectUrl);

                // 로그인 폼으로 리다이렉트
                resp.sendRedirect(contextPath + "/login");
            }
        }
    }

    @Override
    public void destroy() {
    }
}
