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

@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session != null) {
            session.invalidate(); // 세션 무효화 (Redis에서도 삭제됨)
        }

        // 로그아웃 후 로그인 화면으로 리다이렉트
        resp.sendRedirect(req.getContextPath() + "/login");
    }
}
