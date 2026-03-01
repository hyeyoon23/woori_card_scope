<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
  <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
    <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

      <% // Data is provided by TestCustomerServlet via request attributes %>


        <%-- NOTE: request attributes expected: - customer : CustomerDTO - totalSpending : java.math.BigDecimal (or
          Long/Integer) - currentRank : String (e.g., "PLATINUM" ) - nextRank : String (e.g., "VIP" ) - remainingAmount
          : java.math.BigDecimal - progressPercent : java.lang.Double (0~100) - ageGroupLabel : String (e.g., "30-39" )
          - genderLabel : String (e.g., "Female" ) - regionLabel : String (e.g., "Seoul" ) - spendingTypes :
          java.util.List<String> (e.g., ["Dining","Shopping","Travel","Entertainment"])
          --%>

          <!DOCTYPE html>
          <html lang="ko">

          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>Customer Detail</title>

            <style>
              :root {
                --bg: #f6f8fc;
                --card: #ffffff;
                --border: #e6e9f2;
                --text: #111827;
                --muted: #6b7280;
                --primary: #2563eb;
                --primary-100: #e8f0ff;
                --shadow: 0 8px 24px rgba(17, 24, 39, .06);
                --radius: 14px;
              }

              * {
                box-sizing: border-box;
              }

              body {
                margin: 0;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Pretendard, "Noto Sans KR", Arial, sans-serif;
                background: var(--bg);
                color: var(--text);
              }

              .container {
                max-width: 1180px;
                margin: 28px auto 60px;
                padding: 0 18px;
              }

              /* Header */
              .page-title {
                font-size: 26px;
                font-weight: 800;
                letter-spacing: -0.3px;
                margin: 0 0 4px;
              }

              .page-subtitle {
                margin: 0 0 18px;
                color: var(--muted);
                font-size: 14px;
              }

              .card {
                background: var(--card);
                border: 1px solid var(--border);
                border-radius: var(--radius);
                box-shadow: var(--shadow);
              }

              .card-body {
                padding: 22px 24px;
              }

              /* Info row */
              .info-grid {
                display: grid;
                grid-template-columns: 1.2fr 1fr 1fr 1fr 1.2fr;
                gap: 18px;
                align-items: start;
              }

              @media (max-width: 980px) {
                .info-grid {
                  grid-template-columns: 1fr 1fr;
                }
              }

              .label {
                font-size: 13px;
                color: var(--muted);
                margin-bottom: 8px;
              }

              .value {
                font-size: 18px;
                font-weight: 800;
                letter-spacing: -0.2px;
              }

              .value.big {
                font-size: 34px;
                font-weight: 900;
                color: var(--primary);
                text-align: right;
              }

              @media (max-width: 980px) {
                .value.big {
                  text-align: left;
                }
              }

              .badge {
                display: inline-flex;
                align-items: center;
                padding: 8px 14px;
                border-radius: 10px;
                border: 1px solid var(--border);
                background: #f1f5f9;
                font-weight: 800;
                color: #334155;
                margin-top: 8px;
              }

              .divider {
                height: 1px;
                background: var(--border);
                margin: 18px 0;
              }

              /* Pills */
              .pills {
                display: flex;
                flex-wrap: wrap;
                gap: 10px;
                margin-top: 8px;
              }

              .pill {
                border: 1px solid #cfe0ff;
                background: #f5f9ff;
                color: #1d4ed8;
                padding: 6px 12px;
                border-radius: 999px;
                font-size: 13px;
                font-weight: 700;
              }

              /* Rank tracker */
              .section-title {
                font-size: 22px;
                font-weight: 900;
                margin: 0 0 18px;
              }

              .tracker {
                position: relative;
                padding: 6px 0 10px;
              }

              .track-line {
                height: 10px;
                border-radius: 999px;
                background: #e5e7eb;
                position: relative;
                overflow: hidden;
              }

              .track-fill {
                height: 100%;
                width: 0%;
                background: var(--primary);
                border-radius: 999px;
                transition: width .25s ease;
              }

              .track-steps {
                display: flex;
                justify-content: space-between;
                margin-top: 18px;
                padding: 0 6px;
              }

              .step {
                width: 20%;
                text-align: center;
                color: var(--muted);
                font-size: 12px;
                position: relative;
              }

              .dot {
                width: 14px;
                height: 14px;
                border-radius: 50%;
                border: 3px solid #cbd5e1;
                background: #fff;
                margin: -26px auto 8px;
              }

              .step.active .dot {
                border-color: var(--primary);
              }

              .step .rank-name {
                font-weight: 900;
                color: #111827;
                font-size: 13px;
                margin-bottom: 4px;
              }

              .floating-bubble {
                position: absolute;
                top: -4px;
                transform: translateX(-50%);
                background: var(--primary);
                color: #fff;
                font-weight: 900;
                font-size: 13px;
                padding: 7px 10px;
                border-radius: 10px;
                box-shadow: 0 10px 18px rgba(37, 99, 235, .18);
                white-space: nowrap;
                z-index: 10;
              }

              .floating-bubble:after {
                content: "";
                position: absolute;
                left: 50%;
                transform: translateX(-50%);
                bottom: -6px;
                border: 6px solid transparent;
                border-top-color: var(--primary);
              }

              .summary-grid {
                display: grid;
                grid-template-columns: 1fr 1fr 1fr;
                gap: 14px;
                margin-top: 18px;
              }

              @media (max-width: 980px) {
                .summary-grid {
                  grid-template-columns: 1fr;
                }
              }

              .summary-box {
                border: 1px solid var(--border);
                border-radius: 12px;
                padding: 16px 16px;
                background: #fff;
              }

              .summary-box.primary {
                background: var(--primary-100);
                border-color: #d9e6ff;
              }

              .summary-box.warn {
                background: #fff4e6;
                border-color: #ffe2b8;
              }

              .summary-title {
                color: var(--muted);
                font-weight: 700;
                font-size: 13px;
                margin-bottom: 6px;
              }

              .summary-value {
                font-size: 22px;
                font-weight: 900;
                letter-spacing: -0.2px;
              }

              .progress-wrap {
                margin-top: 18px;
              }

              .progress-head {
                display: flex;
                align-items: center;
                justify-content: space-between;
                margin-bottom: 8px;
                color: var(--muted);
                font-size: 13px;
                font-weight: 700;
              }

              .progress-line {
                height: 10px;
                background: #e5e7eb;
                border-radius: 999px;
                overflow: hidden;
              }

              .progress-fill {
                height: 100%;
                width: 0%;
                background: var(--primary);
                border-radius: 999px;
                transition: width .25s ease;
              }
            </style>
          </head>

          <body>
            <div class="container">

              <h1 class="page-title">Woori Card Scope – Member Rank Growth & Spending Insight Analytics Platform</h1>
              <p class="page-subtitle">Internal Customer Analytics Dashboard</p>

              <!-- Top Card -->
              <div class="card" style="margin-top:14px;">
                <div class="card-body">
                  <div class="info-grid">
                    <div>
                      <div class="label">Customer ID</div>
                      <div class="value">
                        <c:out value="${customer.seq}" />
                      </div>

                      <div style="margin-top:16px;">
                        <div class="label">Member Rank</div>
                        <span class="badge">
                          <c:out value="${currentRank}" />
                        </span>
                      </div>
                    </div>

                    <div>
                      <div class="label">Age Group</div>
                      <div class="value">
                        <c:out value="${ageGroupLabel}" />
                      </div>
                    </div>

                    <div>
                      <div class="label">Gender</div>
                      <div class="value">
                        <c:out value="${genderLabel}" />
                      </div>
                    </div>

                    <div>
                      <div class="label">Region</div>
                      <div class="value">
                        <c:out value="${regionLabel}" />
                      </div>
                    </div>

                    <div>
                      <div class="label" style="text-align:right;">Total Spending</div>
                      <div class="value big">
                        <fmt:formatNumber value="${totalSpending}" type="number" groupingUsed="true" />만원
                      </div>
                    </div>
                  </div>

                  <div class="divider"></div>

                  <div>
                    <div class="label">Spending Types</div>
                    <div class="pills">
                      <c:choose>
                        <c:when test="${not empty spendingTypes}">
                          <c:forEach var="t" items="${spendingTypes}">
                            <span class="pill">
                              <c:out value="${t}" />
                            </span>
                          </c:forEach>
                        </c:when>
                        <c:otherwise>
                          <span class="pill">No tags</span>
                        </c:otherwise>
                      </c:choose>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Rank Tracker Card -->
              <div class="card" style="margin-top:18px;">
                <div class="card-body">

                  <h2 class="section-title">Member Rank Growth Tracker</h2>

                  <div class="tracker">
                    <!-- bubble 위치: totalProgressPercent 기반 (0~100) -->
                    <div class="floating-bubble" style="left: ${totalProgressPercent}%; ">
                      <fmt:formatNumber value="${totalSpending}" type="number" groupingUsed="true" />만원
                    </div>

                    <div class="track-line">
                      <div class="track-fill" style="width: ${totalProgressPercent}%;"></div>
                    </div>

                    <!-- 단계는 화면용 고정 예시 (필요하면 서버에서 동적으로 만들 수도 있어) -->
                    <div class="track-steps">
                      <div class="step ${currentRank eq 'GOLD' ? 'active' : ''}">
                        <div class="dot"></div>
                        <div class="rank-name">Gold</div>
                        <div>1,000만원</div>
                      </div>

                      <div class="step ${currentRank eq 'PLATINUM' ? 'active' : ''}">
                        <div class="dot"></div>
                        <div class="rank-name">Platinum</div>
                        <div>2,500만원</div>
                      </div>

                      <div class="step ${currentRank eq 'VIP' ? 'active' : ''}">
                        <div class="dot"></div>
                        <div class="rank-name">VIP</div>
                        <div>5,000만원</div>
                      </div>

                      <div class="step ${currentRank eq 'VVIP' ? 'active' : ''}">
                        <div class="dot"></div>
                        <div class="rank-name">VVIP</div>
                        <div>10,000만원</div>
                      </div>

                      <div class="step">
                        <div class="dot"></div>
                        <div class="rank-name">MAX</div>
                        <div>—</div>
                      </div>
                    </div>
                  </div>

                  <div class="summary-grid">
                    <div class="summary-box primary">
                      <div class="summary-title">Current Rank</div>
                      <div class="summary-value">
                        <c:out value="${currentRank}" />
                      </div>
                    </div>

                    <div class="summary-box">
                      <div class="summary-title">Next Rank</div>
                      <div class="summary-value">
                        <c:out value="${nextRank}" />
                      </div>
                    </div>

                    <div class="summary-box warn">
                      <div class="summary-title" style="color:#c2410c;">Remaining Amount</div>
                      <div class="summary-value" style="color:#7c2d12;">
                        <fmt:formatNumber value="${remainingAmount}" type="number" groupingUsed="true" />만원
                      </div>
                    </div>
                  </div>

                  <div class="progress-wrap">
                    <div class="progress-head">
                      <div>Progress to
                        <c:out value="${nextRank}" />
                      </div>
                      <div>
                        <fmt:formatNumber value="${progressPercent}" type="number" maxFractionDigits="1" />%
                      </div>
                    </div>
                    <div class="progress-line">
                      <div class="progress-fill" style="width: ${progressPercent}%;"></div>
                    </div>
                  </div>

                </div>
              </div>

            </div>
          </body>

          </html>