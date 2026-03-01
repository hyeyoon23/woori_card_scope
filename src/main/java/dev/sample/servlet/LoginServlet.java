package dev.sample.servlet;

import dev.sample.dto.*;
import dev.sample.dao.*;
import dev.sample.service.*;
import dev.sample.config.*;
import dev.sample.filter.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private UserService userService;

    @Override
    public void init() throws ServletException {
        super.init();
        userService = (UserService) getServletContext().getAttribute("USER_SERVICE");
        if (userService == null) {
            throw new ServletException("USER_SERVICE not found in ServletContext");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // 이미 로그인된 사용자는 고객 목록으로 리다이렉트
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("USER") != null) {
            resp.sendRedirect(req.getContextPath() + "/customers");
            return;
        }

        String successMsg = req.getParameter("signup");
        if ("success".equals(successMsg)) {
            req.setAttribute("successMessage", "회원가입이 완료되었습니다. 로그인해주세요.");
        }

        req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String id = req.getParameter("id");
        String password = req.getParameter("password");

        UserDTO user = userService.login(id, password);

        if (user != null) {
            // 로그인 성공: 세션 생성 (RedissonTomcatSessionManager에 의해 Redis에 자동 저장됨)
            HttpSession session = req.getSession(true);
            session.setAttribute("USER", user);

            // 원래 가려고 했던 페이지가 있으면 그리로 이동 (AuthFilter에서 설정)
            String redirectUrl = (String) session.getAttribute("REDIRECT_URL");
            if (redirectUrl != null) {
                session.removeAttribute("REDIRECT_URL");
                resp.sendRedirect(redirectUrl);
            } else {
                resp.sendRedirect(req.getContextPath() + "/customers");
            }
        } else {
            // 로그인 실패
            req.setAttribute("errorMessage", "아이디 또는 비밀번호가 일치하지 않습니다.");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
        }
    }
}
