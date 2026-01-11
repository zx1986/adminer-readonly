import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
    stages: [
        { duration: '10s', target: 20 },  // Ramp up to 20 users
        { duration: '40s', target: 20 },  // Stay at 20 users
        { duration: '10s', target: 0 },   // Ramp down to 0 users
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
        errors: ['rate<0.1'],              // Error rate should be less than 10%
    },
};

const BASE_URL = 'http://localhost:8080';

export default function () {
    // Test 1: Load login page
    const loginPageRes = http.get(BASE_URL);

    const loginPageCheck = check(loginPageRes, {
        'login page status is 200': (r) => r.status === 200,
        'login page contains Adminer': (r) => r.body.includes('Adminer'),
    });

    errorRate.add(!loginPageCheck);

    // Extract CSRF token
    const tokenMatch = loginPageRes.body.match(/name='token' value='([^']+)'/);

    if (tokenMatch && tokenMatch[1]) {
        const token = tokenMatch[1];

        // Build cookie string from response
        const cookies = loginPageRes.cookies;
        let cookieStr = '';
        for (let name in cookies) {
            if (cookieStr) cookieStr += '; ';
            cookieStr += `${name}=${cookies[name][0].value}`;
        }

        // Test 2: Perform login (follow redirects)
        const loginRes = http.post(
            BASE_URL,
            {
                'auth[driver]': 'server',
                'auth[server]': 'mariadb',
                'auth[username]': 'predefined',
                'auth[password]': 'predefined',
                'auth[db]': '',
                'token': token,
            },
            {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'Cookie': cookieStr,
                },
                redirects: 5, // Follow up to 5 redirects
            }
        );

        const loginCheck = check(loginRes, {
            'login successful (200 after redirect)': (r) => r.status === 200,
            'logged in page shows database or server': (r) =>
                r.body.includes('noinch') || r.body.includes('mariadb') || r.body.includes('Database'),
        });

        errorRate.add(!loginCheck);
    }

    sleep(1);
}
