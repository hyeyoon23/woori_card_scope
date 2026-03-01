<%@ page contentType="text/html;charset=UTF-8" language="java" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <!DOCTYPE html>
        <html lang="ko">

        <head>
            <meta charset="UTF-8">
            <title>로그인 - Woori Card Scope</title>
            <style>
                :root {
                    --primary: #2563eb;
                    --primary-hover: #1d4ed8;
                    --bg: #f8fafc;
                }

                body {
                    margin: 0;
                    padding: 0;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                    background-color: var(--bg);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                }

                .login-card {
                    background: #fff;
                    padding: 40px;
                    border-radius: 12px;
                    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
                    width: 100%;
                    max-width: 380px;
                }

                h1 {
                    font-size: 24px;
                    font-weight: 800;
                    color: #1e293b;
                    margin: 0 0 8px;
                    text-align: center;
                }

                p.subtitle {
                    color: #64748b;
                    font-size: 14px;
                    text-align: center;
                    margin-bottom: 24px;
                }

                .form-group {
                    margin-bottom: 16px;
                }

                label {
                    display: block;
                    font-size: 13px;
                    font-weight: 600;
                    color: #334155;
                    margin-bottom: 6px;
                }

                input {
                    width: 100%;
                    padding: 10px 12px;
                    border: 1px solid #cbd5e1;
                    border-radius: 6px;
                    font-size: 14px;
                    box-sizing: border-box;
                    outline: none;
                    transition: border-color 0.2s;
                }

                input:focus {
                    border-color: var(--primary);
                    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
                }

                button {
                    width: 100%;
                    padding: 12px;
                    background-color: var(--primary);
                    color: white;
                    border: none;
                    border-radius: 6px;
                    font-size: 15px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: background-color 0.2s;
                    margin-top: 8px;
                }

                button:hover {
                    background-color: var(--primary-hover);
                }

                .error-msg {
                    color: #ef4444;
                    font-size: 13px;
                    margin-top: -8px;
                    margin-bottom: 16px;
                    text-align: center;
                }

                .success-msg {
                    color: #10b981;
                    font-size: 13px;
                    margin-top: -8px;
                    margin-bottom: 16px;
                    text-align: center;
                }

                .link {
                    display: block;
                    text-align: center;
                    margin-top: 20px;
                    font-size: 14px;
                    color: #64748b;
                    text-decoration: none;
                }

                .link span {
                    color: var(--primary);
                    font-weight: 600;
                }

                .link:hover span {
                    text-decoration: underline;
                }
            </style>
        </head>

        <body>

            <div class="login-card">
                <h1>환영합니다</h1>
                <p class="subtitle">Woori Card Scope 관리자 시스템</p>

                <c:if test="${not empty errorMessage}">
                    <div class="error-msg">${errorMessage}</div>
                </c:if>

                <c:if test="${not empty successMessage}">
                    <div class="success-msg">${successMessage}</div>
                </c:if>

                <form action="${pageContext.request.contextPath}/login" method="post">
                    <div class="form-group">
                        <label for="id">아이디</label>
                        <input type="text" id="id" name="id" placeholder="아이디를 입력하세요" required autofocus>
                    </div>
                    <div class="form-group">
                        <label for="password">비밀번호</label>
                        <input type="password" id="password" name="password" placeholder="비밀번호를 입력하세요" required>
                    </div>
                    <button type="submit">로그인</button>
                </form>

                <a href="${pageContext.request.contextPath}/signup" class="link">
                    계정이 없으신가요? <span>회원가입</span>
                </a>
            </div>

        </body>

        </html>