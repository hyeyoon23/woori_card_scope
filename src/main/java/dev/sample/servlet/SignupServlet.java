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

@WebServlet("/signup")
public class SignupServlet extends HttpServlet {

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

        req.getRequestDispatcher("/WEB-INF/views/signup.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String id = req.getParameter("id");
        String password = req.getParameter("password");
        String name = req.getParameter("name");

        if (id == null || password == null || name == null || id.isEmpty() || password.isEmpty() || name.isEmpty()) {
            req.setAttribute("errorMessage", "모든 항목을 입력해주세요.");
            req.getRequestDispatcher("/WEB-INF/views/signup.jsp").forward(req, resp);
            return;
        }

        boolean success = userService.signup(id, password, name);
        if (success) {
            // 회원가입 성공 시 로그인 페이지로 이동
            resp.sendRedirect(req.getContextPath() + "/login?signup=success");
        } else {
            // 실패 시 (보통 아이디 중복)
            req.setAttribute("errorMessage", "이미 존재하는 아이디거나 가입에 실패했습니다.");
            req.getRequestDispatcher("/WEB-INF/views/signup.jsp").forward(req, resp);
        }
    }
}
