import { v4 as uuidv4 } from 'uuid';
import { UAParser } from 'ua-parser-js';

interface Env {
  DB: D1Database;
}

const documentation = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>Riyales Auth API Documentation</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="icon" href="/assets/favicon.png">
  <style>
    :root {
      /* Light Theme Colors */
      --bg-color-light: #f5f5f7;
      --text-color-light: #1d1d1f;
      --card-bg-light: rgba(255, 255, 255, 0.8);
      --card-border-light: rgba(0, 0, 0, 0.1);
      --code-bg-light: #e9e9eb;
      --divider-color-light: #dcdce0;
      --secondary-color-light: #6e6e73;
      --primary-color-light: rgb(0, 90, 227);

      /* Dark Theme Colors */
      --bg-color-dark: #000000;
      --text-color-dark: #f5f5f7;
      --card-bg-dark: rgba(29, 29, 31, 0.7);
      --card-border-dark: rgba(255, 255, 255, 0.1);
      --code-bg-dark: #1d1d1f;
      --divider-color-dark: #2d2d2f;
      --secondary-color-dark: #86868b;
      --primary-color-dark: rgb(0, 90, 227);

      /* Shared Colors */
      --method-get: rgb(34, 197, 102);
      --method-post: rgb(0, 90, 227);
      --warning-color: rgb(255, 50, 65);
    }
    
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'SF Pro Icons', 'Helvetica Neue', Helvetica, Arial, sans-serif;
      line-height: 1.5;
      padding: 0;
      margin: 0;
      transition: background-color 0.3s ease, color 0.3s ease;
    }
    
    body.light {
      background-color: var(--bg-color-light);
      color: var(--text-color-light);
    }
    
    body.dark {
      background-color: var(--bg-color-dark);
      color: var(--text-color-dark);
    }
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    
    .container {
      max-width: 1300px;
      margin: 0 auto;
      padding: 3rem;
    }
    
    header {
      margin-bottom: 2rem;
      text-align: center;
      padding: 3rem 0;
    }
    
    h1, h2, h3, h4, h5, h6, summary {
        font-family: 'Inter', sans-serif;
    }

    h1 {
      font-size: 2.5rem;
      font-weight: 700;
      margin-bottom: 0.5rem;
      letter-spacing: -0.02em;
    }
    
    h2 {
      font-size: 1.8rem;
      font-weight: 600;
      margin: 3rem 0 1.5rem;
      padding-bottom: 0.75rem;
      letter-spacing: -0.01em;
    }
    
    body.light h2 { border-bottom: 1px solid var(--divider-color-light); }
    body.dark h2 { border-bottom: 1px solid var(--divider-color-dark); }
    
    h3 {
      font-size: 1.25rem;
      font-weight: 600;
      margin: 1.5rem 0 0.75rem;
      letter-spacing: -0.01em;
    }
     h5 {
      font-size: 1rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
    }
    
    p {
      margin-bottom: 1rem;
    }
    
    .subtitle {
      font-size: 1.25rem;
      margin-bottom: 2rem;
    }
    
    body.light .subtitle { color: var(--secondary-color-light); }
    body.dark .subtitle { color: var(--secondary-color-dark); }

    .card {
      border-radius: 18px;
      padding: 1.5rem 2rem;
      margin-bottom: 2rem;
      transition: background-color 0.3s ease, border 0.3s ease;
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
    }

    body.light .card {
      background: var(--card-bg-light);
      border: 1px solid var(--card-border-light);
      box-shadow: 0 4px 24px rgba(0,0,0,0.05);
    }
    body.dark .card {
      background: var(--card-bg-dark);
      border: 1px solid var(--card-border-dark);
      box-shadow: 0 4px 24px rgba(0,0,0,0.2);
    }
    
    .card ul {
        padding-left: 1.5rem;
    }

    .endpoint-header {
      display: flex;
      align-items: center;
      margin-bottom: 1rem;
      flex-wrap: wrap;
      gap: 0.5rem;
    }
    
    .method {
      display: inline-block;
      padding: 0.25rem 0.75rem;
      border-radius: 6px;
      font-weight: 600;
      font-size: 0.875rem;
      color: white;
      text-transform: uppercase;
    }
    
    .method.get { background-color: var(--method-get); }
    .method.post { background-color: var(--method-post); }
    
    .endpoint-path {
      font-family: 'SF Mono', SFMono-Regular, ui-monospace, monospace;
      font-size: 1rem;
      padding: 0.25rem 0.75rem;
      border-radius: 6px;
    }
    
    body.light .endpoint-path { background-color: var(--code-bg-light); }
    body.dark .endpoint-path { background-color: var(--code-bg-dark); }
    
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 1rem 0;
      font-size: 0.9rem;
    }
    
    th {
      text-align: left;
      padding: 0.75rem 1rem;
      font-weight: 600;
    }
    body.light th {
      border-bottom: 1px solid var(--divider-color-light);
      color: var(--secondary-color-light);
    }
    body.dark th {
      border-bottom: 1px solid var(--divider-color-dark);
      color: var(--secondary-color-dark);
    }
    
    td {
      padding: 0.75rem 1rem;
      vertical-align: top;
    }
    body.light td { border-bottom: 1px solid var(--divider-color-light); }
    body.dark td { border-bottom: 1px solid var(--divider-color-dark); }
    
    tr:last-child td { border-bottom: none; }
    
    .code-block {
      position: relative;
      border-radius: 12px;
      padding: 1rem;
      margin: 1rem 0;
      overflow-x: auto;
      font-family: 'SF Mono', SFMono-Regular, ui-monospace, monospace;
      font-size: 0.9rem;
      line-height: 1.4;
    }
    body.light .code-block { background-color: var(--code-bg-light); }
    body.dark .code-block { background-color: var(--code-bg-dark); }
    
    .copy-button {
      position: absolute;
      top: 0.75rem;
      right: 0.75rem;
      border: none;
      border-radius: 8px;
      padding: 0.3rem 0.6rem;
      font-size: 0.75rem;
      cursor: pointer;
      opacity: 0.7;
      transition: opacity 0.2s;
      background-color: rgba(122, 122, 122, 0.4);
      backdrop-filter: blur(5px);
      -webkit-backdrop-filter: blur(5px);
      color: white;
    }
    
    .copy-button:hover { opacity: 1; }
    
    .note {
      border-left: 3px solid var(--warning-color);
      padding: 1rem 1.5rem;
      border-radius: 10px;
      margin: 1rem 0;
      background-color: rgba(255, 69, 84, 0.1);
    }
    
    .note h4 {
      color: var(--warning-color);
      margin-top: 0;
      margin-bottom: 0.5rem;
      font-size: 1rem;
    }
    
    .parameter-table td:first-child {
      font-family: 'SF Mono', SFMono-Regular, ui-monospace, monospace;
      font-weight: 500;
    }
    
    .parameter-table th:first-child, .parameter-table td:first-child { width: 25%; }
    .parameter-table th:nth-child(2), .parameter-table td:nth-child(2) { width: 15%; }
    .parameter-table th:nth-child(3), .parameter-table td:nth-child(3) { width: 15%; }
    .parameter-table th:nth-child(4), .parameter-table td:nth-child(4) { width: 45%; }
    
    .required { color: var(--warning-color); }
    .optional {
      body.light & { color: var(--secondary-color-light); }
      body.dark & { color: var(--secondary-color-dark); }
    }
    
    .endpoint-description { margin: 1rem 0; }
    
    .tabs {
      display: flex;
      margin: 1rem 0 0;
    }
    body.light .tabs { border-bottom: 1px solid var(--divider-color-light); }
    body.dark .tabs { border-bottom: 1px solid var(--divider-color-dark); }

    .tab {
      padding: 0.5rem 1rem;
      cursor: pointer;
      border-bottom: 2px solid transparent;
      font-weight: 500;
      margin-bottom: -1px;
    }
    
    .tab.active {
      border-bottom: 2px solid var(--primary-color-dark);
    }
    body.light .tab.active { color: var(--primary-color-light); }
    body.dark .tab.active { color: var(--primary-color-dark); }
    
    .tab-content {
      display: none;
      padding: 1rem 0;
      opacity: 0;
      transition: opacity 0.3s ease-in-out;
    }
    
    .tab-content.active {
      display: block;
      opacity: 1;
    }
    
    footer {
      text-align: center;
      padding: 2rem 0;
      font-size: 0.9rem;
    }
    body.light footer { color: var(--secondary-color-light); }
    body.dark footer { color: var(--secondary-color-dark); }

    .accordion {
        border-top: 1px solid var(--divider-color-dark);
    }
    body.light .accordion {
        border-top: 1px solid var(--divider-color-light);
    }
    .accordion-item {
        border-bottom: 1px solid var(--divider-color-dark);
    }
    body.light .accordion-item {
        border-bottom: 1px solid var(--divider-color-light);
    }
    .accordion-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1.25rem 0.5rem;
        cursor: pointer;
    }
    .accordion-title {
        display: flex;
        align-items: center;
        gap: 1rem;
        flex-wrap: wrap;
    }
    .accordion-title .description {
        color: var(--secondary-color-dark);
    }
    body.light .accordion-title .description {
        color: var(--secondary-color-light);
    }
    .accordion-title code {
        font-family: 'SF Mono', SFMono-Regular, ui-monospace, monospace;
    }
    .accordion-toggle {
        font-size: 1.75rem;
        font-weight: 400;
        transition: transform 0.3s ease;
        flex-shrink: 0;
        margin-left: 1rem;
        line-height: 1;
    }
    .accordion-item.active .accordion-toggle {
        transform: rotate(45deg);
    }
    .accordion-content {
        max-height: 0;
        overflow: hidden;
        transition: max-height 0.4s ease-in-out;
    }
    .accordion-content-inner {
        padding: 0rem 0.5rem 1.5rem 0.5rem;
    }
    .accordion-item.active .accordion-content {
        max-height: 1000px; /* Adjust as needed */
    }

    @media (max-width: 768px) {
      .container { padding: 1rem; }
      header { padding: 1rem 0; }
      h1 { font-size: 2rem; }
      .endpoint-header { flex-direction: column; align-items: flex-start; }
      .endpoint-path { margin-left: 0; margin-top: 0.5rem; font-size: 0.9rem; max-width: 100%; }
      .parameter-table td, .parameter-table tr { display: block; width: 100%; }
      .parameter-table tr { margin-bottom: 1rem; border-bottom: 1px solid var(--divider-color-dark); }
      .parameter-table tr:last-child { border-bottom: none; }
      body.light .parameter-table tr { border-bottom: 1px solid var(--divider-color-light); }
    }
  </style>
</head>
<body class="dark">
  <div class="container">
    <!-- <header> -->
      <!-- <h1>Riyales Documentation</h1> -->
      <!-- <p class="subtitle">A robust API for tracking device metrics, logging application events, and reporting analytics for the Riyales application ecosystem.</p> -->
    <!-- </header> -->

    <div class="card section">
      <h2>Overview</h2>
      <p>Welcome to the Riyales Auth API. This service provides a comprehensive suite of endpoints for collecting device and event statistics, logging application errors, and generating insightful reports. This document outlines the available resources, authentication methods, and provides practical examples to facilitate seamless integration.</p>
    </div>

    <h2>Authentication</h2>
    <div class="card">
      <p>All API requests require authentication using the <code>X-API-Key</code> header:</p>
      <ul>
        <li>For data collection endpoints (<code>/device</code>, <code>/event</code>, <code>/error</code>), use a key in format: <code>RYLS-UUID</code></li>
        <li>For reporting endpoints (<code>/report/*</code>), use key: <code>RYLS-0***</code></li>
      </ul>
      
      <div class="note">
        <h4>Important</h4>
        <p>API Keys for data collection endpoints must follow the format <code>RYLS-</code> followed by a valid UUID v4 (e.g., <code>RYLS-123e4567-e89b-12d3-a456-426614174000</code>). The reporting key is a static value provided to authorized users.</p>
      </div>
    </div>
    
    <h2>Data Collection Endpoints</h2>
    <div class="card">
      <p>These endpoints are used to submit data to the Riyales system. All are POST requests and require a valid <code>RYLS-UUID</code> API key.</p>
        <table>
          <tr>
            <th>Endpoint</th>
            <th>Method</th>
            <th>Description</th>
          </tr>
          <tr>
            <td><code>/device</code></td>
            <td><span class="method post">POST</span></td>
            <td>Records device information and statistics.</td>
          </tr>
          <tr>
            <td><code>/event</code></td>
            <td><span class="method post">POST</span></td>
            <td>Records a specific in-app event.</td>
          </tr>
          <tr>
            <td><code>/error</code></td>
            <td><span class="method post">POST</span></td>
            <td>Logs an application error or crash.</td>
          </tr>
        </table>
    </div>

    <!-- Device endpoint -->
    <div class="card">
      <div class="endpoint-header">
        <span class="method post">POST</span>
        <span class="endpoint-path">/device</span>
      </div>
      
      <div class="endpoint-description">
        <p>Records device information and increases the count for this device profile in the database.</p>
      </div>
      
      <h3>Headers</h3>
      <table class="parameter-table">
        <tr>
          <th>Name</th>
          <th>Type</th>
          <th>Required</th>
          <th>Description</th>
        </tr>
        <tr>
          <td>Content-Type</td>
          <td>String</td>
          <td class="required">Required</td>
          <td>application/json</td>
        </tr>
        <tr>
          <td>X-API-Key</td>
          <td>String</td>
          <td class="required">Required</td>
          <td>RYLS-UUID format</td>
        </tr>
        <tr>
          <td>User-Agent</td>
          <td>String</td>
          <td class="optional">Recommended</td>
          <td>Browser/device user agent</td>
        </tr>
      </table>
      
      <h3>Request Parameters</h3>
      <table class="parameter-table">
        <tr>
          <th>Parameter</th>
          <th>Type</th>
          <th>Required</th>
          <th>Description</th>
        </tr>
        <tr>
          <td>device_brand</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Brand of the device (e.g., "Apple", "Samsung")</td>
        </tr>
        <tr>
          <td>device_model</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Model of the device (e.g., "iPhone 14", "Galaxy S21")</td>
        </tr>
        <tr>
          <td>os_name</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Operating system name (e.g., "iOS", "Android")</td>
        </tr>
        <tr>
          <td>os_version</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Operating system version (e.g., "16.0", "13")</td>
        </tr>
        <tr>
          <td>device_type</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Type of device (e.g., "mobile", "tablet", "desktop")</td>
        </tr>
        <tr>
          <td>network_type</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Network connection type (e.g., "wifi", "cellular")</td>
        </tr>
        <tr>
          <td>device_language</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Device language setting (e.g., "en_US", "fa_IR")</td>
        </tr>
        <tr>
          <td>push_notification_enabled</td>
          <td>Boolean</td>
          <td class="optional">Optional</td>
          <td>Whether push notifications are enabled (0 or 1)</td>
        </tr>
        <tr>
          <td>install_timestamp</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Timestamp of app installation (ISO 8601 format)</td>
        </tr>
      </table>
      
      <div class="accordion" style="border-top: none; margin-top: 1.5rem;">
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <h3 style="margin: 0; font-size: 1.1rem; font-weight: 600;">Example Request</h3>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner" style="padding-top: 1rem;">
                    <div class="tabs">
                        <div class="tab active" onclick="switchTab(this, 'device-curl')">cURL</div>
                        <div class="tab" onclick="switchTab(this, 'device-js')">JavaScript</div>
                    </div>
                    <div id="device-curl" class="tab-content active">
                        <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl -X POST https://auth.ryls.ir/device \\
-H "Content-Type: application/json" \\
-H "X-API-Key: RYLS-123e4567-e89b-12d3-a456-426614174000" \\
-H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)" \\
-d '{
  "device_brand": "Apple",
  "device_model": "iPhone 14",
  "os_name": "iOS",
  "os_version": "16.0",
  "network_type": "cellular"
}'</code></pre></div>
                    </div>
                    <div id="device-js" class="tab-content">
                        <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>fetch('https://auth.ryls.ir/device', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': 'RYLS-123e4567-e89b-12d3-a456-426614174000'
  },
  body: JSON.stringify({
    device_brand: 'Apple',
    device_model: 'iPhone 14',
    os_name: 'iOS',
    os_version: '16.0',
    network_type: 'cellular'
  })
})
.then(response => response.json())
.then(data => console.log(data));</code></pre></div>
                    </div>
                </div>
            </div>
        </div>
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <h3 style="margin: 0; font-size: 1.1rem; font-weight: 600;">Response</h3>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner" style="padding-top: 1rem;">
                    <div class="code-block" style="margin-top:0;"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>{
  "message": "Device stats updated"
}</code></pre></div>
                </div>
            </div>
        </div>
      </div>
    </div>
    
    <!-- Event endpoint -->
    <div class="card">
      <div class="endpoint-header">
        <span class="method post">POST</span>
        <span class="endpoint-path">/event</span>
      </div>
      
      <div class="endpoint-description">
        <p>Records an event occurrence and increases its count in the database.</p>
      </div>
      
      <h3>Headers</h3>
      <table class="parameter-table">
        <tr>
          <th>Name</th>
          <th>Type</th>
          <th>Required</th>
          <th>Description</th>
        </tr>
        <tr>
          <td>Content-Type</td>
          <td>String</td>
          <td class="required">Required</td>
          <td>application/json</td>
        </tr>
        <tr>
          <td>X-API-Key</td>
          <td>String</td>
          <td class="required">Required</td>
          <td>RYLS-UUID format</td>
        </tr>
      </table>
      
      <h3>Request Parameters</h3>
      <table class="parameter-table">
        <tr>
          <th>Parameter</th>
          <th>Type</th>
          <th>Required</th>
          <th>Description</th>
        </tr>
        <tr>
          <td>event_type</td>
          <td>String</td>
          <td class="required">Required</td>
          <td>Type of event (e.g., "tab_visit", "button_click")</td>
        </tr>
        <tr>
          <td>event_data</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>JSON string with additional event data</td>
        </tr>
      </table>
      
      <div class="accordion" style="border-top: none; margin-top: 1.5rem;">
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <h3 style="margin: 0; font-size: 1.1rem; font-weight: 600;">Example Request</h3>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner" style="padding-top: 1rem;">
                    <div class="tabs">
                        <div class="tab active" onclick="switchTab(this, 'event-curl')">cURL</div>
                        <div class="tab" onclick="switchTab(this, 'event-js')">JavaScript</div>
                    </div>
                    <div id="event-curl" class="tab-content active">
                        <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl -X POST https://auth.ryls.ir/event \\
-H "Content-Type: application/json" \\
-H "X-API-Key: RYLS-123e4567-e89b-12d3-a456-426614174000" \\
-d '{
  "event_type": "tab_visit",
  "event_data": "{\\"tab\\": \\"settings\\", \\"duration\\": 45}"
}'</code></pre></div>
                    </div>
                    <div id="event-js" class="tab-content">
                        <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>fetch('https://auth.ryls.ir/event', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': 'RYLS-123e4567-e89b-12d3-a456-426614174000'
  },
  body: JSON.stringify({
    event_type: 'tab_visit',
    event_data: JSON.stringify({ tab: 'settings', duration: 45 })
  })
})
.then(response => response.json())
.then(data => console.log(data));</code></pre></div>
                    </div>
                </div>
            </div>
        </div>
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <h3 style="margin: 0; font-size: 1.1rem; font-weight: 600;">Response</h3>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner" style="padding-top: 1rem;">
                    <div class="code-block" style="margin-top:0;"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>{
  "message": "Event stats updated"
}</code></pre></div>
                </div>
            </div>
        </div>
      </div>
    </div>
    
    <!-- Error endpoint -->
    <div class="card">
      <div class="endpoint-header">
        <span class="method post">POST</span>
        <span class="endpoint-path">/error</span>
      </div>
      
      <div class="endpoint-description">
        <p>Logs application errors for later analysis.</p>
      </div>
      
      <h3>Headers</h3>
      <table class="parameter-table">
        <tr>
          <th>Name</th>
          <th>Type</th>
          <th>Required</th>
          <th>Description</th>
        </tr>
        <tr>
          <td>Content-Type</td>
          <td>String</td>
          <td class="required">Required</td>
          <td>application/json</td>
        </tr>
        <tr>
          <td>X-API-Key</td>
          <td>String</td>
          <td class="required">Required</td>
          <td>RYLS-UUID format</td>
        </tr>
      </table>
      
      <h3>Request Parameters</h3>
      <table class="parameter-table">
        <tr>
          <th>Parameter</th>
          <th>Type</th>
          <th>Required</th>
          <th>Description</th>
        </tr>
        <tr>
          <td>error_message</td>
          <td>String</td>
          <td class="required">Required</td>
          <td>Error message text</td>
        </tr>
        <tr>
          <td>error_cause</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Cause of the error</td>
        </tr>
        <tr>
          <td>error_code</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Error code identifier</td>
        </tr>
        <tr>
          <td>timestamp</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>When the error occurred (ISO 8601 format)</td>
        </tr>
        <tr>
          <td>os_name</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Operating system name</td>
        </tr>
        <tr>
          <td>os_version</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Operating system version</td>
        </tr>
        <tr>
          <td>device_model</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Device model</td>
        </tr>
        <tr>
          <td>device_brand</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Device brand</td>
        </tr>
        <tr>
          <td>app_version</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Application version</td>
        </tr>
        <tr>
          <td>stack_trace</td>
          <td>String</td>
          <td class="optional">Optional</td>
          <td>Error stack trace</td>
        </tr>
      </table>
      
      <div class="accordion" style="border-top: none; margin-top: 1.5rem;">
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <h3 style="margin: 0; font-size: 1.1rem; font-weight: 600;">Example Request</h3>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner" style="padding-top: 1rem;">
                    <div class="tabs">
                        <div class="tab active" onclick="switchTab(this, 'error-curl')">cURL</div>
                        <div class="tab" onclick="switchTab(this, 'error-js')">JavaScript</div>
                    </div>
                    <div id="error-curl" class="tab-content active">
                        <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl -X POST https://auth.ryls.ir/error \\
-H "Content-Type: application/json" \\
-H "X-API-Key: RYLS-123e4567-e89b-12d3-a456-426614174000" \\
-d '{
  "error_message": "Failed to load user data",
  "error_cause": "Network timeout",
  "error_code": "E1001",
  "app_version": "1.2.0"
}'</code></pre></div>
                    </div>
                    <div id="error-js" class="tab-content">
                        <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>fetch('https://auth.ryls.ir/error', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': 'RYLS-123e4567-e89b-12d3-a456-426614174000'
  },
  body: JSON.stringify({
    error_message: 'Failed to load user data',
    error_cause: 'Network timeout',
    error_code: 'E1001',
    app_version: '1.2.0'
  })
})
.then(response => response.json())
.then(data => console.log(data));</code></pre></div>
                    </div>
                </div>
            </div>
        </div>
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <h3 style="margin: 0; font-size: 1.1rem; font-weight: 600;">Response</h3>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner" style="padding-top: 1rem;">
                    <div class="code-block" style="margin-top:0;"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>{
  "message": "Error logged"
}</code></pre></div>
                </div>
            </div>
        </div>
      </div>
    </div>

    <!-- Reporting Endpoints -->
    <div class="card">
      <h2>Reporting Endpoints</h2>
      <div class="note">
        <h4>Authentication for Reports</h4>
        <p>All report endpoints require the API key <code>RYLS-0***</code> in the X-API-Key header.</p>
      </div>
      <p>These endpoints provide aggregated and filterable data. Click an endpoint to see examples.</p>
      
      <h3>Headers</h3>
        <table class="parameter-table">
            <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Required</th>
                <th>Description</th>
            </tr>
            <tr>
                <td>X-API-Key</td>
                <td>String</td>
                <td class="required">Required</td>
                <td>Static API key for reporting access (<code>RYLS-0***</code>)</td>
            </tr>
        </table>

      <h3 style="margin-top: 2.5rem;">Aggregated Reports</h3>
      <div class="accordion">
        
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)"><div class="accordion-title"><span class="method get">GET</span><code>/report/os_name</code><span class="description">Total count per OS name.</span></div><div class="accordion-toggle">+</div></div>
            <div class="accordion-content"><div class="accordion-content-inner">
                <h5>Example Request</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/os_name" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                <h5>Example Response</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  { "os_name": "iOS", "count": 5200 },
  { "os_name": "Android", "count": 8340 }
]</code></pre></div>
            </div></div>
        </div>

        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)"><div class="accordion-title"><span class="method get">GET</span><code>/report/os_version</code><span class="description">Total count per OS version.</span></div><div class="accordion-toggle">+</div></div>
            <div class="accordion-content"><div class="accordion-content-inner">
                <h5>Example Request</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/os_version" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                <h5>Example Response</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  { "os_version": "16.1", "count": 3100 },
  { "os_version": "13", "count": 4500 }
]</code></pre></div>
            </div></div>
        </div>

        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)"><div class="accordion-title"><span class="method get">GET</span><code>/report/device_brand</code><span class="description">Total count per device brand.</span></div><div class="accordion-toggle">+</div></div>
            <div class="accordion-content"><div class="accordion-content-inner">
                <h5>Example Request</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/device_brand" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                <h5>Example Response</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  { "device_brand": "Apple", "count": 5200 },
  { "device_brand": "Samsung", "count": 6100 }
]</code></pre></div>
            </div></div>
        </div>
        
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)"><div class="accordion-title"><span class="method get">GET</span><code>/report/network_type</code><span class="description">Total count per network type.</span></div><div class="accordion-toggle">+</div></div>
            <div class="accordion-content"><div class="accordion-content-inner">
                <h5>Example Request</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/network_type" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                <h5>Example Response</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  { "network_type": "wifi", "count": 9500 },
  { "network_type": "cellular", "count": 4040 }
]</code></pre></div>
            </div></div>
        </div>
        
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)"><div class="accordion-title"><span class="method get">GET</span><code>/report/event_type</code><span class="description">Total count per event type.</span></div><div class="accordion-toggle">+</div></div>
            <div class="accordion-content"><div class="accordion-content-inner">
                <h5>Example Request</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/event_type" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                <h5>Example Response</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  { "event_type": "tab_visit", "count": 12500 },
  { "event_type": "login_success", "count": 8000 }
]</code></pre></div>
            </div></div>
        </div>

        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)"><div class="accordion-title"><span class="method get">GET</span><code>/report/error_code</code><span class="description">Total count per error code.</span></div><div class="accordion-toggle">+</div></div>
            <div class="accordion-content"><div class="accordion-content-inner">
                <h5>Example Request</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/error_code" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                <h5>Example Response</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  { "error_code": "E1001", "count": 50 },
  { "error_code": "E404", "count": 120 }
]</code></pre></div>
            </div></div>
        </div>
        
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)"><div class="accordion-title"><span class="method get">GET</span><code>/report/error_cause</code><span class="description">Total count per error cause.</span></div><div class="accordion-toggle">+</div></div>
            <div class="accordion-content"><div class="accordion-content-inner">
                <h5>Example Request</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/error_cause" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                <h5>Example Response</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  { "error_cause": "Network timeout", "count": 50 },
  { "error_cause": "Database error", "count": 120 }
]</code></pre></div>
            </div></div>
        </div>
        
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)"><div class="accordion-title"><span class="method get">GET</span><code>/report/app_version</code><span class="description">Total count per application version.</span></div><div class="accordion-toggle">+</div></div>
            <div class="accordion-content"><div class="accordion-content-inner">
                <h5>Example Request</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/app_version" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                <h5>Example Response</h5><div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  { "app_version": "1.2.0", "count": 50 },
  { "app_version": "1.0.0", "count": 120 }
]</code></pre></div>
            </div></div>
        </div>
      </div>

      <h3 style="margin-top: 2.5rem;">Detailed & Filterable Reports</h3>
      <div class="accordion">
        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <div class="accordion-title">
                    <span class="method get">GET</span>
                    <code>/report/combined</code>
                    <span class="description">Comprehensive summary of all device statistics.</span>
                </div>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner">
                    <h5>Example Request</h5>
                    <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/combined" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                    <h5>Example Response</h5>
                    <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>{
  "os_name": [ { "os_name": "iOS", "count": 5200 }, ... ],
  "device_brand": [ { "device_brand": "Apple", "count": 5200 }, ... ],
  "push_notification_enabled": [ { "enabled": true, "count": 9800 }, ... ],
  "...": "..."
}</code></pre></div>
                </div>
            </div>
        </div>

        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <div class="accordion-title">
                    <span class="method get">GET</span>
                    <code>/report/devices</code>
                    <span class="description">Lists raw device data with filtering.</span>
                </div>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner">
                    <p>Supports filtering by any parameter in the device stats table.</p>
                    <h5>Example Request</h5>
                    <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/devices?device_brand=Apple" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                    <h5>Example Response</h5>
                    <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  {
    "os_name": "iOS",
    "os_version": "16.1",
    "device_brand": "Apple",
    "count": 150
  },
  "..."
]</code></pre></div>
                </div>
            </div>
        </div>

        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <div class="accordion-title">
                    <span class="method get">GET</span>
                    <code>/report/events</code>
                    <span class="description">Lists raw event data with filtering.</span>
                </div>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner">
                    <p>Supports filtering by <code>event_type</code> and <code>event_data</code>.</p>
                    <h5>Example Request</h5>
                    <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/events?event_type=tab_visit" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                    <h5>Example Response</h5>
                    <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  {
    "event_type": "tab_visit",
    "event_data": "{\"tab\":\"settings\",\"duration\":45}",
    "count": 12
  },
  "..."
]</code></pre></div>
                </div>
            </div>
        </div>

        <div class="accordion-item">
            <div class="accordion-header" onclick="toggleAccordion(this)">
                <div class="accordion-title">
                    <span class="method get">GET</span>
                    <code>/report/errors</code>
                    <span class="description">Lists raw error data with filtering.</span>
                </div>
                <div class="accordion-toggle">+</div>
            </div>
            <div class="accordion-content">
                <div class="accordion-content-inner">
                    <p>Supports filtering by any parameter in the error table.</p>
                    <h5>Example Request</h5>
                    <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>curl "https://auth.ryls.ir/report/errors?app_version=1.2.0" \\
-H "X-API-Key: RYLS-0***"</code></pre></div>
                    <h5>Example Response</h5>
                    <div class="code-block"><button class="copy-button" onclick="copyCode(this)">Copy</button><pre><code>[
  {
    "id": 1,
    "error_message": "Failed to load user data",
    "error_cause": "Network timeout",
    "error_code": "E1001",
    "timestamp": "2023-09-15T14:30:00Z",
    "os_name": "iOS",
    "os_version": "16.0",
    "device_model": "iPhone 14",
    "device_brand": "Apple",
    "app_version": "1.2.0",
    "stack_trace": "at fetchUserData (app.js:42)..."
  },
  "..."
]</code></pre></div>
                </div>
            </div>
        </div>
      </div>
    </div>
    
  </div>
  
  <footer>
    <p>Riyales | &copy; <span id="copyright-year"></span> Aurum</p>
  </footer>

  <script>
    document.addEventListener('DOMContentLoaded', () => {
        document.getElementById('copyright-year').textContent = new Date().getFullYear();
        document.body.classList.add('dark');
    });
    
    function switchTab(tabElement, tabId) {
      const parentCard = tabElement.closest('.card');
      if (!parentCard) return;
      const tabContents = parentCard.querySelectorAll('.tab-content');
      tabContents.forEach(content => content.classList.remove('active'));
      const tabs = parentCard.querySelectorAll('.tab');
      tabs.forEach(tab => tab.classList.remove('active'));
      const selectedTabContent = parentCard.querySelector('#' + tabId);
      if (selectedTabContent) {
        selectedTabContent.classList.add('active');
      }
      tabElement.classList.add('active');
    }
    
    function copyCode(button) {
      const codeBlock = button.parentElement;
      if (!codeBlock) return;
      const code = codeBlock.querySelector('code');
      if (!code) return;
      
      navigator.clipboard.writeText(code.innerText).then(() => {
        const originalText = button.textContent;
        button.textContent = 'Copied!';
        button.style.color = 'var(--method-get)';
        
        setTimeout(() => {
          button.textContent = originalText;
          button.style.color = 'white';
        }, 2000);
      }).catch(err => {
        console.error('Failed to copy: ', err);
      });
    }

    function toggleAccordion(headerElement) {
        const item = headerElement.parentElement;
        if (item) {
            item.classList.toggle('active');
        }
    }
  </script>
</body>
</html>
`;

const statsPage = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>Riyales Analytics Dashboard</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
  <link rel="icon" href="/assets/favicon.png">
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    :root {
      /* Dark Theme Colors */
      --bg-color-dark: #000000;
      --text-color-dark: #f5f5f7;
      --card-bg-dark: rgba(29, 29, 31, 0.65);
      --card-border-dark: rgba(255, 255, 255, 0.07);
      --divider-color-dark: #2d2d2f;
      --secondary-color-dark: #86868b;
      --primary-color-dark: rgb(0, 120, 255);

      /* Accent Colors - Vibrant palette */
      --accent-blue: rgb(0, 110, 255);
      --accent-green: rgb(53, 236, 99);
      --accent-orange: rgb(255, 145, 0);
      --accent-red: rgb(255, 57, 47);
      --accent-purple: rgb(184, 63, 245);
      --accent-yellow: rgb(255, 218, 31);
      --accent-pink: rgb(255, 55, 95);
      --accent-teal: rgb(113, 222, 255);
      --accent-indigo: rgb(94, 80, 216);
      --accent-mint: rgb(0, 209, 181);
      --accent-cyan: rgb(39, 161, 218);
      --accent-lime: rgb(142, 250, 0);
      --accent-brown: rgb(172, 142, 104);
      --accent-peach: rgb(255, 178, 62);
      --accent-lavender: rgb(175, 82, 222);
      --accent-gold: rgb(255, 166, 0);
      --accent-coral: rgb(255, 111, 97);
      --accent-turquoise: rgb(48, 213, 200);
      --accent-magenta: rgb(255, 64, 255);
      --accent-emerald: rgb(0, 208, 132);
    }
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'SF Pro Icons', 'Helvetica Neue', Helvetica, Arial, sans-serif;
      background-color: var(--bg-color-dark);
      color: var(--text-color-dark);
      line-height: 1.5;
      padding: 0;
      margin: 0;
      font-weight: 300;
    }
    
    .container {
      max-width: 1300px;
      margin: 0 auto;
      padding: 2rem;
    }
    
    h2 {
      font-size: 1.8rem;
      margin: 2rem 0 1rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid var(--divider-color-dark);
      font-weight: 500;
      letter-spacing: -0.02em;
    }
    
    h3 {
      font-size: 1.25rem;
      margin: 1.5rem 0 0.75rem;
      font-weight: 500;
      letter-spacing: -0.02em;
    }
    
    .dashboard-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
      gap: 1.5rem;
      margin-bottom: 3rem;
    }
    
    .chart-card {
      border-radius: 24px;
      background: var(--card-bg-dark);
      border: 1px solid var(--card-border-dark);
      padding: 1.5rem;
      backdrop-filter: blur(25px);
      -webkit-backdrop-filter: blur(25px);
      box-shadow: 0 4px 30px rgba(0, 0, 0, 0.1);
      transition: all 0.3s ease;
      display: flex;
      flex-direction: column;
      min-height: 350px;
    }
    
    .chart-card:hover {
      box-shadow: 0 0 20px rgba(255, 255, 255, 0.05), 
                  0 0 30px rgba(255, 255, 255, 0.03),
                  inset 0 0 15px rgba(255, 255, 255, 0.03);
      border: 1px solid rgba(255, 255, 255, 0.12);
    }
    
    .chart-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.5rem;
    }
    
    .chart-title {
      font-size: 1.1rem;
      font-weight: 400;
    }
    
    .chart-container {
      flex: 1;
      position: relative;
      height: 250px;
      transition: height 0.4s ease;
    }
    
    .toggle-buttons {
      display: flex;
      gap: 0.5rem;
    }
    
    .toggle-button {
      background: rgba(255, 255, 255, 0.05);
      border: none;
      color: var(--text-color-dark);
      border-radius: 8px;
      padding: 0.3rem 0.6rem;
      font-size: 0.8rem;
      cursor: pointer;
      transition: background-color 0.2s, box-shadow 0.2s;
    }
    
    .toggle-button:hover {
      background: rgba(255, 255, 255, 0.1);
    }
    
    .toggle-button.active {
      background: var(--primary-color-dark);
      box-shadow: 0 0 10px rgba(0, 120, 255, 0.5);
    }
    
    .loading-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.8);
      display: flex;
      justify-content: center;
      align-items: center;
      z-index: 1000;
      backdrop-filter: blur(8px);
    }
    
    .loading-spinner {
      width: 50px;
      height: 50px;
      border: 2px solid rgba(255, 255, 255, 0.1);
      border-radius: 50%;
      border-top-color: var(--primary-color-dark);
      animation: spin 0.8s ease-in-out infinite;
    }
    
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    
    .error-message {
      background: rgba(255, 59, 48, 0.1);
      color: var(--accent-red);
      padding: 1rem;
      border-radius: 12px;
      margin: 1rem 0;
      border-left: 3px solid var(--accent-red);
    }
    
    .api-key-form {
      max-width: 500px;
      margin: 4rem auto;
      background: var(--card-bg-dark);
      border: 1px solid var(--card-border-dark);
      border-radius: 24px;
      padding: 2.5rem;
      backdrop-filter: blur(25px);
      -webkit-backdrop-filter: blur(25px);
      box-shadow: 0 4px 30px rgba(0, 0, 0, 0.2);
    }
    
    .api-key-form p {
      margin-bottom: 1.5rem;
      color: var(--secondary-color-dark);
    }
    
    input[type="text"] {
      width: 100%;
      background: rgba(0, 0, 0, 0.3);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      padding: 1rem 1.2rem;
      color: var(--text-color-dark);
      font-size: 1rem;
      margin-bottom: 1.5rem;
      transition: all 0.2s ease;
    }
    
    input[type="text"]:focus {
      outline: none;
      border-color: rgba(0, 120, 255, 0.4);
      box-shadow: 0 0 0 2px rgba(0, 120, 255, 0.1);
    }
    
    button {
      width: 100%;
      background: var(--primary-color-dark);
      color: white;
      border: none;
      border-radius: 12px;
      padding: 1rem;
      font-size: 1rem;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s ease;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1), 0 1px 3px rgba(0, 0, 0, 0.1);
    }
    
    button:hover {
      background: rgb(10, 132, 255);
      box-shadow: 0 6px 10px rgba(0, 0, 0, 0.15), 0 1px 3px rgba(0, 0, 0, 0.1),
                  0 0 15px rgba(10, 132, 255, 0.3);
      transform: translateY(-1px);
    }
    
    button:active {
      transform: translateY(1px);
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
    
    .section-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.5rem;
      color: var(--secondary-color-dark);
    }
    
    footer {
      text-align: center;
      padding: 2rem 0;
      color: var(--secondary-color-dark);
      font-size: 0.9rem;
    }
    
    @media (max-width: 768px) {
      .container {
        padding: 1rem;
      }
      .dashboard-grid, #eventTrackingGrid, #errorReportingGrid {
        grid-template-columns: 1fr;
      }
      .api-key-form {
        padding: 1.5rem;
      }
    }
    
    .no-data-card {
      grid-column: 1 / -1;
      background: rgba(29, 29, 31, 0.5);
      border: 1px solid var(--card-border-dark);
      border-radius: 24px;
      padding: 4rem 2rem;
      text-align: center;
      color: var(--secondary-color-dark);
      font-size: 1rem;
      backdrop-filter: blur(15px);
      -webkit-backdrop-filter: blur(15px);
    }
    
    body.login-view {
      display: flex;
      flex-direction: column;
      min-height: 100vh;
    }
    body.login-view .container {
      flex: 1 0 auto;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    body.login-view .api-key-form {
      margin-top: 0;
      margin-bottom: 0;
    }
    body.login-view footer {
       flex-shrink: 0;
    }
    
    #apiKeyInput {
      font-family: 'SF Mono', SFMono-Regular, ui-monospace, monospace;
    }

    #eventTrackingGrid, #errorReportingGrid {
        grid-template-columns: repeat(3, 1fr);
    }
    #eventTrackingGrid .chart-card, #errorReportingGrid .chart-card {
        aspect-ratio: 1 / 1;
    }
    
    .no-data-in-card {
        display: flex;
        align-items: center;
        justify-content: center;
        height: 100%;
        color: var(--secondary-color-dark);
    }

    #chartjs-tooltip {
      opacity: 0;
      position: absolute;
      background: rgba(29, 29, 31, 0.75);
      backdrop-filter: blur(15px);
      -webkit-backdrop-filter: blur(15px);
      border-radius: 8px;
      border: 1px solid rgba(255, 255, 255, 0.1);
      color: white;
      padding: 0.75rem 1rem;
      pointer-events: none;
      transition: all .2s ease;
      font-family: 'Inter', sans-serif;
      font-size: 0.875rem;
      min-width: 150px;
    }
    
    #chartjs-tooltip table {
        width: 100%;
        border-collapse: collapse;
    }
    #chartjs-tooltip th {
        font-weight: 500;
        text-align: left;
        padding-bottom: 0.5rem;
        border-bottom: 1px solid var(--divider-color-dark);
    }
    #chartjs-tooltip td {
        padding-top: 0.5rem;
    }

    @media (max-width: 1024px) {
        #eventTrackingGrid, #errorReportingGrid {
            grid-template-columns: repeat(2, 1fr);
        }
    }
    
    #snackbar {
      visibility: hidden;
      min-width: 250px;
      background-color: var(--accent-red);
      color: #fff;
      text-align: center;
      border-radius: 12px;
      padding: 16px;
      position: fixed;
      z-index: 1001;
      left: 50%;
      transform: translateX(-50%);
      bottom: 30px;
      font-size: 0.95rem;
      font-weight: 500;
      box-shadow: 0 5px 25px rgba(0,0,0,0.3);
      opacity: 0;
      transition: all 0.4s cubic-bezier(0.21, 1.02, 0.73, 1);
    }

    #snackbar.show {
      visibility: visible;
      opacity: 1;
      bottom: 40px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div id="apiKeySection" class="api-key-form">
      <h3>Enter Your API Key</h3>
      <p>Enter your reporting API key to access analytics data.</p>
      <input type="text" id="apiKeyInput" placeholder="RYLS-" value="RYLS-" autofocus>
      <button id="loadDataButton">Load Dashboard</button>
    </div>
    
    <div id="dashboardContent" style="display: none;">
      <h2>Device Metrics</h2>
      <div class="section-header">
        <p>Overview of device types, operating systems, and hardware specs.</p>
      </div>
      
      <div class="dashboard-grid" id="deviceMetricsGrid">
        <!-- OS Name Chart -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-title">Operating System Distribution</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="osNameChart">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="osNameChart">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="osNameChart"></canvas>
          </div>
        </div>
        
        <!-- OS Version Chart -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-title">OS Version Distribution</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="osVersionChart">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="osVersionChart">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="osVersionChart"></canvas>
          </div>
        </div>
        
        <!-- Device Brand Chart -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-title">Device Brand Distribution</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="deviceBrandChart">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="deviceBrandChart">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="deviceBrandChart"></canvas>
          </div>
        </div>
        
        <!-- Device Type Chart -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-title">Device Type Distribution</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="deviceTypeChart">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="deviceTypeChart">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="deviceTypeChart"></canvas>
          </div>
        </div>
        
        <!-- Network Type Chart -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-title">Network Connection Type</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="networkTypeChart">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="networkTypeChart">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="networkTypeChart"></canvas>
          </div>
        </div>
        
        <!-- Push Notification Chart -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-title">Push Notification Status</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="pushNotificationChart">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="pushNotificationChart">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="pushNotificationChart"></canvas>
          </div>
        </div>
      </div>
      
      <h2>Event Tracking</h2>
      <div class="section-header">
        <p>Analysis of user interactions and events within the application.</p>
      </div>
      
      <div class="dashboard-grid" id="eventTrackingGrid">
        <!-- Event Type Charts will be added dynamically -->
      </div>
      
      <h2>Error Reporting</h2>
      <div class="section-header">
        <p>Overview of application errors and crash reports.</p>
      </div>
      
      <div class="dashboard-grid" id="errorReportingGrid">
        <!-- Error Code Chart -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-title">Error Code Distribution</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="errorCodeChart">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="errorCodeChart">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="errorCodeChart"></canvas>
          </div>
        </div>
        
        <!-- Error Cause Chart -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-title">Error Cause Distribution</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="errorCauseChart">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="errorCauseChart">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="errorCauseChart"></canvas>
          </div>
        </div>
        
        <!-- App Version Chart -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-title">App Version Distribution</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="appVersionChart">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="appVersionChart">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="appVersionChart"></canvas>
          </div>
        </div>
      </div>
    </div>
  </div>
  
  <div id="loadingOverlay" class="loading-overlay" style="display: none;">
    <div class="loading-spinner"></div>
  </div>
  
  <div id="snackbar"></div>

  <footer>
    <p>Riyales | &copy; <span id="copyright-year"></span> Aurum</p>
  </footer>

  <script>
    document.addEventListener('DOMContentLoaded', () => {
      document.getElementById('copyright-year').textContent = new Date().getFullYear();
      document.body.classList.add('login-view');
      const apiKeyInput = document.getElementById('apiKeyInput');
      if (apiKeyInput) {
        apiKeyInput.focus();
        apiKeyInput.addEventListener('keydown', (event) => {
          if (event.key === 'Enter') {
            event.preventDefault();
            document.getElementById('loadDataButton').click();
          }
        });
      }
    });
    
    // Chart colors - Expanded vibrant colors palette
    const chartColors = [
      'rgb(10, 116, 255)',  // blue
      'rgb(39, 235, 65)',   // green
      'rgb(255, 136, 0)',  // orange
      'rgb(255, 63, 53)',   // red
      'rgb(172, 33, 252)',  // purple
      'rgb(255, 217, 28)',  // yellow
      'rgb(248, 48, 148)',   // pink
      'rgb(100, 224, 255)', // teal
      'rgb(108, 79, 235)',   // indigo
      'rgb(0, 182, 173)',   // mint
      'rgb(74, 233, 159)',  // cyan
      'rgb(112, 250, 0)',   // lime
      'rgb(172, 142, 104)', // brown
      'rgb(255, 158, 48)',  // peach
      'rgb(175, 82, 222)',  // lavender
      'rgb(255, 184, 0)',   // gold
      'rgb(255, 111, 97)',  // coral
      'rgb(48, 213, 200)',  // turquoise
      'rgb(255, 64, 255)',  // magenta
      'rgb(0, 208, 132)'    // emerald
    ];

    const externalTooltipHandler = (context) => {
      const {chart, tooltip} = context;
      let tooltipEl = chart.canvas.parentNode.querySelector('div#chartjs-tooltip');

      if (!tooltipEl) {
        tooltipEl = document.createElement('div');
        tooltipEl.id = 'chartjs-tooltip';
        chart.canvas.parentNode.appendChild(tooltipEl);
      }

      if (tooltip.opacity === 0) {
        tooltipEl.style.opacity = 0;
        return;
      }

      if (tooltip.body) {
        const titleLines = tooltip.title || [];
        const bodyLines = tooltip.body.map(b => b.lines);

        let innerHtml = '<table>';
        if (titleLines.length > 0) {
            innerHtml += '<thead><tr><th>' + titleLines.join(' ') + '</th></tr></thead>';
        }
        
        innerHtml += '<tbody>';
        bodyLines.forEach(function(body, i) {
            const dataPoint = tooltip.dataPoints[i];
            const value = dataPoint.raw;
            const total = chart.data.datasets[0].data.map(v => Number(v)).reduce((a, b) => a + b, 0);
            const percentage = total > 0 ? ((value / total) * 100).toFixed(1) + '%' : '0%';
            const label = dataPoint.label;
            innerHtml += \`<tr><td>\${label}: \${value} (\${percentage})</td></tr>\`;
        });
        innerHtml += '</tbody></table>';

        tooltipEl.innerHTML = innerHtml;
      }

      const {offsetLeft: positionX, offsetTop: positionY} = chart.canvas;

      tooltipEl.style.opacity = 1;
      let left = positionX + tooltip.caretX + 15;
      if (left + tooltipEl.offsetWidth > chart.canvas.width) {
        left = positionX + tooltip.caretX - tooltipEl.offsetWidth - 15;
      }
      let top = positionY + tooltip.caretY + 15;
       if (top + tooltipEl.offsetHeight > chart.canvas.height) {
        top = positionY + tooltip.caretY - tooltipEl.offsetHeight - 15;
      }

      tooltipEl.style.left = left + 'px';
      tooltipEl.style.top = top + 'px';
    };
    
    // Chart instances
    const charts = {};
    
    // Toggle chart type buttons
    document.querySelectorAll('.toggle-button').forEach(button => {
      button.addEventListener('click', () => {
        const chartType = button.getAttribute('data-chart-type');
        const targetChart = button.getAttribute('data-target');
        const chartGroup = button.closest('.toggle-buttons');
        
        // Update active state
        chartGroup.querySelectorAll('.toggle-button').forEach(btn => {
          btn.classList.remove('active');
        });
        button.classList.add('active');
        
        // Update chart type
        updateChartType(targetChart, chartType);
      });
    });
    
    // Load data button
    document.getElementById('loadDataButton').addEventListener('click', () => {
      const apiKey = document.getElementById('apiKeyInput').value.trim();
      if (!apiKey) {
        showSnackBar('Please enter an API key');
        return;
      }
      
      loadDashboardData(apiKey);
    });
    
    // Function to load all dashboard data
    async function loadDashboardData(apiKey) {
      showLoading(true);
      
      try {
        // Fetch all data in parallel
        const results = await Promise.all([
          fetchData('/report/combined', apiKey).catch(e => { console.error("Failed to fetch combined data:", e); return null; }),
          fetchData('/report/event_type', apiKey).catch(e => { console.error("Failed to fetch event types:", e); return null; }),
          fetchData('/report/error_code', apiKey).catch(e => { console.error("Failed to fetch error codes:", e); return null; }),
          fetchData('/report/error_cause', apiKey).catch(e => { console.error("Failed to fetch error causes:", e); return null; }),
          fetchData('/report/app_version', apiKey).catch(e => { console.error("Failed to fetch app versions:", e); return null; })
        ]);

        const [
            combinedData,
            eventTypeData,
            errorCodeData,
            errorCauseData,
            appVersionData
        ] = results;
        
        // If all requests failed, it's very likely the API key is invalid.
        if (results.every(r => r === null)) {
            throw new Error('Invalid API Key');
        }

        // Show dashboard content
        document.body.classList.remove('login-view');
        document.getElementById('apiKeySection').style.display = 'none';
        document.getElementById('dashboardContent').style.display = 'block';
        
        // Initialize charts with data, only if data is available
        if (combinedData) initializeCharts(combinedData);
        
        if (eventTypeData && eventTypeData.length > 0) {
          await initializeEventCharts(eventTypeData);
        } else {
          document.getElementById('eventTrackingGrid').innerHTML = '<div class="no-data-card">No event data available.</div>';
        }

        initializeErrorCharts(errorCodeData, errorCauseData, appVersionData);
        
      } catch (error) {
        if (error.message === 'Invalid API Key') {
            showSnackBar('Invalid API Key. Please try again.');
        } else {
            showSnackBar('Failed to load dashboard. Check connection.');
        }
        
        // Reset to login view
        document.body.classList.add('login-view');
        document.getElementById('apiKeySection').style.display = 'block';
        document.getElementById('dashboardContent').style.display = 'none';
      } finally {
        showLoading(false);
      }
    }
    
    // Fetch data from API
    async function fetchData(endpoint, apiKey) {
      const response = await fetch(endpoint, {
        headers: {
          'X-API-Key': apiKey
        }
      });
      
      if (!response.ok) {
        throw new Error(\`API request failed: \${response.status} \${response.statusText}\`);
      }
      
      return await response.json();
    }
    
    // Initialize device metrics charts
    function initializeCharts(data) {
      // OS Name Chart
      createChart('osNameChart', 'bar', {
        labels: data.os_name.map(item => capitalizeFirstLetter(item.os_name || 'Unknown')),
        datasets: [{
          label: 'Count',
          data: data.os_name.map(item => item.count),
          backgroundColor: chartColors
        }]
      });
      
      // OS Version Chart
      createChart('osVersionChart', 'bar', {
        labels: data.os_version.map(item => capitalizeFirstLetter(item.os_version || 'Unknown')),
        datasets: [{
          label: 'Count',
          data: data.os_version.map(item => item.count),
          backgroundColor: chartColors
        }]
      });
      
      // Device Brand Chart
      createChart('deviceBrandChart', 'bar', {
        labels: data.device_brand.map(item => capitalizeFirstLetter(item.device_brand || 'Unknown')),
        datasets: [{
          label: 'Count',
          data: data.device_brand.map(item => item.count),
          backgroundColor: chartColors
        }]
      });
      
      // Device Type Chart
      createChart('deviceTypeChart', 'bar', {
        labels: data.device_type.map(item => capitalizeFirstLetter(item.device_type || 'Unknown')),
        datasets: [{
          label: 'Count',
          data: data.device_type.map(item => item.count),
          backgroundColor: chartColors
        }]
      });
      
      // Network Type Chart
      createChart('networkTypeChart', 'bar', {
        labels: data.network_type.map(item => capitalizeFirstLetter(item.network_type || 'Unknown')),
        datasets: [{
          label: 'Count',
          data: data.network_type.map(item => item.count),
          backgroundColor: chartColors
        }]
      });
      
      // Push Notification Chart
      createChart('pushNotificationChart', 'bar', {
        labels: data.push_notification_enabled.map(item => item.enabled ? 'Enabled' : 'Disabled'),
        datasets: [{
          label: 'Count',
          data: data.push_notification_enabled.map(item => item.count),
          backgroundColor: chartColors
        }]
      });
    }
    
    // Initialize event tracking charts
    async function initializeEventCharts(data) {
      const eventTrackingGrid = document.getElementById('eventTrackingGrid');
      eventTrackingGrid.innerHTML = '';
      const apiKey = document.getElementById('apiKeyInput').value.trim();

      for (const [index, event] of data.entries()) {
        const canvasId = \`eventChart_\${index}\`;
        const chartCard = document.createElement('div');
        chartCard.className = 'chart-card';
        
        let chartTitle = \`\${capitalizeFirstLetter(event.event_type)} Events\`;
        
        chartCard.innerHTML = \`
          <div class="chart-header">
            <div class="chart-title">\${chartTitle}</div>
            <div class="toggle-buttons">
              <button class="toggle-button active" data-chart-type="bar" data-target="\${canvasId}">Bar</button>
              <button class="toggle-button" data-chart-type="pie" data-target="\${canvasId}">Pie</button>
            </div>
          </div>
          <div class="chart-container">
            <canvas id="\${canvasId}"></canvas>
          </div>
        \`;
        
        eventTrackingGrid.appendChild(chartCard);
        
        // Add event listeners to the new buttons
        chartCard.querySelectorAll('.toggle-button').forEach(button => {
          button.addEventListener('click', () => {
            const chartType = button.getAttribute('data-chart-type');
            const targetChart = button.getAttribute('data-target');
            const chartGroup = button.closest('.toggle-buttons');
            
            chartGroup.querySelectorAll('.toggle-button').forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
            updateChartType(targetChart, chartType);
          });
        });

        if (event.event_type === 'tab_visit') {
          try {
            const detailData = await fetchData(\`/report/event_detail?type=tab_visit&key=tab\`, apiKey);
            if (detailData && detailData.length > 0) {
              chartCard.querySelector('.chart-title').textContent = 'Tab Visit Distribution';
              createChart(canvasId, 'bar', {
                labels: detailData.map(item => capitalizeFirstLetter(item.value || 'Unknown')),
                datasets: [{
                  label: 'Visits',
                  data: detailData.map(item => item.count),
                  backgroundColor: chartColors
                }]
              });
            } else {
              chartCard.querySelector('.chart-container').innerHTML = '<div class="no-data-in-card">No Detailed Data</div>';
            }
          } catch (e) {
            console.error('Failed to fetch event details:', e);
            chartCard.querySelector('.chart-container').innerHTML = '<div class="no-data-in-card">Error Loading Details</div>';
          }
        } else {
          // Fallback for other event types
          createChart(canvasId, 'bar', {
            labels: [capitalizeFirstLetter(event.event_type)],
            datasets: [{
              label: 'Count',
              data: [event.count],
              backgroundColor: chartColors
            }]
          });
        }
      }
    }
    
    // Initialize error reporting charts
    function initializeErrorCharts(errorCodeData, errorCauseData, appVersionData) {
      const setupErrorChart = (canvasId, data) => {
          const chartCard = document.getElementById(canvasId).closest('.chart-card');
          const container = chartCard.querySelector('.chart-container');
          const buttons = chartCard.querySelector('.toggle-buttons');

          if (data && data.length > 0) {
              createChart(canvasId, 'bar', {
                labels: data.map(item => capitalizeFirstLetter(item[Object.keys(item)[0]] || 'Unknown')),
                datasets: [{
                  label: 'Count',
                  data: data.map(item => item.count),
                  backgroundColor: chartColors
                }]
              });
              if(buttons) buttons.style.display = 'flex';
          } else {
              container.innerHTML = '<div class="no-data-in-card">No Data Available</div>';
              if(buttons) buttons.style.display = 'none';
          }
      };

      setupErrorChart('errorCodeChart', errorCodeData);
      setupErrorChart('errorCauseChart', errorCauseData);
      setupErrorChart('appVersionChart', appVersionData);
    }
    
    // Create a chart
    function createChart(canvasId, type, data) {
      const canvas = document.getElementById(canvasId);
      if (!canvas) return;
      
      const ctx = canvas.getContext('2d');
      
      // Destroy existing chart if it exists
      if (charts[canvasId]) {
        charts[canvasId].destroy();
      }
      
      // Create new chart
      charts[canvasId] = new Chart(ctx, {
        type: type,
        data: data,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          animation: {
            duration: 600,
            easing: 'easeOutQuart'
          },
          plugins: {
            legend: {
              display: type === 'pie',
              position: 'right',
              labels: {
                color: '#f5f5f7',
                font: {
                  weight: '300'
                },
                padding: 15
              }
            },
            tooltip: {
                enabled: false,
                external: externalTooltipHandler
            }
          },
          elements: {
            bar: {
              borderRadius: 8,
              borderSkipped: false,
              barPercentage: 0.6,
              categoryPercentage: 0.7
            },
            arc: {
              borderWidth: 0,
              borderColor: 'transparent'
            }
          },
          scales: type === 'bar' ? {
            x: {
              ticks: {
                color: '#a0a0a5',
                font: {
                  weight: '300'
                }
              },
              grid: {
                display: false,
                drawBorder: false
              }
            },
            y: {
              beginAtZero: true,
              ticks: {
                color: '#a0a0a5',
                font: {
                  weight: '300'
                },
                callback: function(value) {
                  if (value >= 1000000) return (value / 1000000).toFixed(1).replace(/\.0$/, '') + 'M';
                  if (value >= 1000) return (value / 1000).toFixed(1).replace(/\.0$/, '') + 'K';
                  return value;
                }
              },
              grid: {
                color: 'rgba(45, 45, 47, 0.3)',
                drawBorder: false
              }
            }
          } : undefined
        }
      });
      
    }
    
    // Update chart type with smooth transition
    function updateChartType(chartId, newType) {
      const chart = charts[chartId];
      if (!chart) return;
      
      const container = document.getElementById(chartId).closest('.chart-container');
      const data = chart.data;
      
      // First, fade out the chart
      container.style.opacity = '0.5';
      
      // After a short delay, destroy and recreate the chart
      setTimeout(() => {
        // Destroy existing chart
        chart.destroy();
        
        // Re-assign the full color palette for the new chart type
        data.datasets[0].backgroundColor = chartColors;

        createChart(chartId, newType, data);
        
        // Adjust container height for pie charts
        if (newType === 'pie') {
          container.style.height = '280px';
        } else {
          container.style.height = '250px';
        }
        
        // Fade the chart back in
        setTimeout(() => {
          container.style.opacity = '1';
        }, 100);
      }, 150);
    }
    
    function capitalizeFirstLetter(string) {
      if (!string) return '';
      return string.charAt(0).toUpperCase() + string.slice(1);
    }
    
    // Show/hide loading overlay
    function showLoading(show) {
      document.getElementById('loadingOverlay').style.display = show ? 'flex' : 'none';
    }

    function showSnackBar(message) {
      const snackbar = document.getElementById('snackbar');
      if (!snackbar) return;
      snackbar.textContent = message;
      snackbar.className = 'show';
      setTimeout(function(){ snackbar.className = snackbar.className.replace('show', ''); }, 3000);
    }
  </script>
</body>
</html>
`;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const method = request.method;

    // Serve stats page
    if (method === 'GET' && url.pathname === '/stats') {
      return new Response(statsPage, {
        status: 200,
        headers: { 'Content-Type': 'text/html' },
      });
    }

    // Serve documentation
    if (method === 'GET' && (url.pathname === '/documentation' || (url.pathname === '/report' && !request.headers.get('X-API-Key')))) {
        return new Response(documentation, {
            status: 200,
            headers: { 'Content-Type': 'text/html' },
        });
    }

    // Validate API Key
    const apiKey = request.headers.get('X-API-Key');
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'API Key required' }), { status: 403 });
    }

    // Handle root endpoint
    if (method === 'GET' && url.pathname === '/') {
      return new Response(JSON.stringify({ message: 'Welcome to Riyales auth service.' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Handle /report endpoints
    if (url.pathname.startsWith('/report')) {
      if (apiKey !== 'RYLS-0009') { // Use the specific API key
        return new Response(JSON.stringify({ error: 'Invalid API Key for report' }), { status: 403 });
      }
      if (method === 'GET') {
        return await handleReport(request, env);
      }
    }

    // Handle /device, /event, /error endpoints
    const uuidRegex = /^RYLS-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(apiKey)) {
      // Don't return error if it's a report endpoint, as that's already handled
      if (!url.pathname.startsWith('/report')) {
           return new Response(JSON.stringify({ error: 'Invalid API Key format' }), { status: 403 });
      }
    }

    if (method === 'POST') {
      try {
        const body = await request.json();
        if (url.pathname === '/device') {
          return await handleDeviceInfo(request, env, body);
        } else if (url.pathname === '/event') {
          return await handleEvent(request, env, body);
        } else if (url.pathname === '/error') {
          return await handleError(request, env, body);
        }
      } catch (error) {
        const err = error as Error;
        return new Response(JSON.stringify({ error: 'Invalid request', details: err.message }), {
          status: 400,
        });
      }
    }

    return new Response(JSON.stringify({ error: 'Method Not Allowed or Invalid Endpoint' }), { status: 405 });
  },
};

async function handleDeviceInfo(request: Request, env: Env, body: any): Promise<Response> {
  const userAgent = request.headers.get('User-Agent') || 'Unknown';
  const parser = new UAParser(userAgent);

  const data = {
    os_name: body.os_name || parser.getOS().name || 'Unknown',
    os_version: body.os_version || parser.getOS().version || 'Unknown',
    device_type: body.device_type || parser.getDevice().type || 'Unknown',
    device_model: body.device_model || parser.getDevice().model || 'Unknown',
    device_brand: body.device_brand || parser.getDevice().vendor || 'Unknown',
    network_type: body.network_type || 'Unknown',
    device_language: body.device_language || 'Unknown',
    push_notification_enabled: body.push_notification_enabled ? 1 : 0,
    install_date: body.install_timestamp ? new Date(body.install_timestamp).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
  };

  try {
    // Try to increment count if combination exists
    const result = await env.DB.prepare(`
      UPDATE device_stats
      SET count = count + 1
      WHERE os_name = ? AND os_version = ? AND device_type = ? AND device_model = ?
            AND device_brand = ? AND network_type = ? AND device_language = ?
            AND push_notification_enabled = ? AND install_date = ?
      RETURNING count
    `)
      .bind(
        data.os_name, data.os_version, data.device_type, data.device_model,
        data.device_brand, data.network_type, data.device_language,
        data.push_notification_enabled, data.install_date
      )
      .first();

    if (!result) {
      // Insert new combination with count = 1
      await env.DB.prepare(`
        INSERT INTO device_stats (
          os_name, os_version, device_type, device_model, device_brand,
          network_type, device_language, push_notification_enabled, install_date, count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
      `)
        .bind(
          data.os_name, data.os_version, data.device_type, data.device_model,
          data.device_brand, data.network_type, data.device_language,
          data.push_notification_enabled, data.install_date
        )
        .run();
    }
    return new Response(JSON.stringify({ message: 'Device stats updated' }), { status: 200 });
  } catch (error) {
    const err = error as Error;
    return new Response(JSON.stringify({ error: 'Failed to update stats', details: err.message }), { status: 500 });
  }
}

async function handleEvent(request: Request, env: Env, body: any): Promise<Response> {
  const data = {
    event_type: body.event_type || 'Unknown',
    event_data: body.event_data || '{}',
  };

  if (!data.event_type) {
    return new Response(JSON.stringify({ error: 'Missing event_type' }), { status: 400 });
  }

  try {
    // Try to increment count if event exists
    const result = await env.DB.prepare(`
      UPDATE event_stats
      SET count = count + 1
      WHERE event_type = ? AND event_data = ?
      RETURNING count
    `)
      .bind(data.event_type, data.event_data)
      .first();

    if (!result) {
      // Insert new event with count = 1
      await env.DB.prepare(`
        INSERT INTO event_stats (event_type, event_data, count)
        VALUES (?, ?, 1)
      `)
        .bind(data.event_type, data.event_data)
        .run();
    }
    return new Response(JSON.stringify({ message: 'Event stats updated' }), { status: 200 });
  } catch (error) {
    const err = error as Error;
    return new Response(JSON.stringify({ error: 'Failed to update stats', details: err.message }), { status: 500 });
  }
}

async function handleError(request: Request, env: Env, body: any): Promise<Response> {
  const data = {
    error_message: body.error_message || 'Unknown error',
    error_cause: body.error_cause || 'Unknown cause',
    error_code: body.error_code || 'Unknown',
    timestamp: body.timestamp || new Date().toISOString(),
    os_name: body.os_name || 'Unknown',
    os_version: body.os_version || 'Unknown',
    device_model: body.device_model || 'Unknown',
    device_brand: body.device_brand || 'Unknown',
    app_version: body.app_version || 'Unknown',
    stack_trace: body.stack_trace || 'No stack trace provided',
  };

  try {
    await env.DB.prepare(`
      INSERT INTO app_errors (
        error_message, error_cause, error_code, timestamp, os_name, os_version,
        device_model, device_brand, app_version, stack_trace
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `)
      .bind(
        data.error_message, data.error_cause, data.error_code, data.timestamp,
        data.os_name, data.os_version, data.device_model, data.device_brand,
        data.app_version, data.stack_trace
      )
      .run();
    return new Response(JSON.stringify({ message: 'Error logged' }), { status: 200 });
  } catch (error) {
    const err = error as Error;
    return new Response(JSON.stringify({ error: 'Failed to log error', details: err.message }), { status: 500 });
  }
}

async function handleReport(request: Request, env: Env): Promise<Response> {
    const { pathname, searchParams } = new URL(request.url);
    try {
        if (pathname.startsWith('/report/event_detail')) {
            const eventType = searchParams.get('type');
            const eventKey = searchParams.get('key');
            
            if (!eventType || !eventKey) {
                return new Response(JSON.stringify({ error: 'Missing type or key parameter' }), { status: 400 });
            }

            // D1 uses SQLite JSON functions. We extract the key from the event_data JSON string.
            const query = `
                SELECT 
                    json_extract(event_data, '$.' || ?) as value, 
                    SUM(count) AS count
                FROM event_stats
                WHERE event_type = ?
                GROUP BY value
                HAVING value IS NOT NULL;
            `;
            
            const { results } = await env.DB.prepare(query).bind(eventKey, eventType).all();
            
            return new Response(JSON.stringify(results), { 
                status: 200, 
                headers: { 'Content-Type': 'application/json' } 
            });
        }

        if (pathname === '/report/os_name') {
            const { results } = await env.DB.prepare('SELECT os_name, SUM(count) AS count FROM device_stats GROUP BY os_name').all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/os_version') {
            const { results } = await env.DB.prepare('SELECT os_version, SUM(count) AS count FROM device_stats GROUP BY os_version').all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/device_brand') {
            const { results } = await env.DB.prepare('SELECT device_brand, SUM(count) AS count FROM device_stats GROUP BY device_brand').all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/network_type') {
            const { results } = await env.DB.prepare('SELECT network_type, SUM(count) AS count FROM device_stats GROUP BY network_type').all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/event_type') {
            const { results } = await env.DB.prepare('SELECT event_type, SUM(count) as count FROM event_stats GROUP BY event_type').all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/error_code') {
            const { results } = await env.DB.prepare('SELECT error_code, COUNT(*) as count FROM app_errors GROUP BY error_code').all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/error_cause') {
            const { results } = await env.DB.prepare('SELECT error_cause, COUNT(*) as count FROM app_errors GROUP BY error_cause').all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/app_version') {
            const { results } = await env.DB.prepare('SELECT app_version, COUNT(*) as count FROM app_errors GROUP BY app_version').all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/combined') {
           const [
                os_name, os_version, device_type, device_model, device_brand,
                network_type, device_language, push_notification_enabled, install_date
            ] = await Promise.all([
                env.DB.prepare('SELECT os_name, SUM(count) as count FROM device_stats GROUP BY os_name').all(),
                env.DB.prepare('SELECT os_version, SUM(count) as count FROM device_stats GROUP BY os_version').all(),
                env.DB.prepare('SELECT device_type, SUM(count) as count FROM device_stats GROUP BY device_type').all(),
                env.DB.prepare('SELECT device_model, SUM(count) as count FROM device_stats GROUP BY device_model').all(),
                env.DB.prepare('SELECT device_brand, SUM(count) as count FROM device_stats GROUP BY device_brand').all(),
                env.DB.prepare('SELECT network_type, SUM(count) as count FROM device_stats GROUP BY network_type').all(),
                env.DB.prepare('SELECT device_language, SUM(count) as count FROM device_stats GROUP BY device_language').all(),
                env.DB.prepare('SELECT push_notification_enabled, SUM(count) as count FROM device_stats GROUP BY push_notification_enabled').all(),
                env.DB.prepare('SELECT install_date, SUM(count) as count FROM device_stats GROUP BY install_date').all()
            ]);

            const response = {
                os_name: os_name.results,
                os_version: os_version.results,
                device_type: device_type.results,
                device_model: device_model.results,
                device_brand: device_brand.results,
                network_type: network_type.results,
                device_language: device_language.results,
                push_notification_enabled: push_notification_enabled.results.map((r: any) => ({ enabled: r.push_notification_enabled === 1, count: r.count })),
                install_date: install_date.results,
            };
            return new Response(JSON.stringify(response), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/devices') {
            const allowedFilters = ['os_name', 'os_version', 'device_type', 'device_model', 'device_brand', 'network_type', 'device_language', 'push_notification_enabled', 'install_date'];
            const filters = [];
            const bindings = [];
            for (const [key, value] of searchParams.entries()) {
                if (allowedFilters.includes(key)) {
                    filters.push(`${key} = ?`);
                    bindings.push(value);
                }
            }
            let query = 'SELECT * FROM device_stats';
            if (filters.length > 0) {
                query += ' WHERE ' + filters.join(' AND ');
            }
            const { results } = await env.DB.prepare(query).bind(...bindings).all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/events') {
            const allowedFilters = ['event_type', 'event_data'];
            const filters = [];
            const bindings = [];
            for (const [key, value] of searchParams.entries()) {
                if (allowedFilters.includes(key)) {
                    filters.push(`${key} = ?`);
                    bindings.push(value);
                }
            }
            let query = 'SELECT * FROM event_stats';
            if (filters.length > 0) {
                query += ' WHERE ' + filters.join(' AND ');
            }
            const { results } = await env.DB.prepare(query).bind(...bindings).all();
            return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else if (pathname === '/report/errors') {
          const allowedFilters = ['error_message', 'error_cause', 'error_code', 'os_name', 'os_version', 'device_model', 'device_brand', 'app_version'];
          const filters = [];
          const bindings = [];
          for (const [key, value] of searchParams.entries()) {
              if (allowedFilters.includes(key)) {
                  filters.push(`${key} = ?`);
                  bindings.push(value);
              }
          }
          let query = 'SELECT * FROM app_errors';
          if (filters.length > 0) {
              query += ' WHERE ' + filters.join(' AND ');
          }
          const { results } = await env.DB.prepare(query).bind(...bindings).all();
          return new Response(JSON.stringify(results), { status: 200, headers: { 'Content-Type': 'application/json' } });
        } else {
          return new Response(JSON.stringify({ 
            error: 'Invalid report endpoint',
          }), { status: 404, headers: { 'Content-Type': 'application/json' } });
        }
    } catch (error) {
      const err = error as Error;
      return new Response(JSON.stringify({ error: 'Failed to fetch data', details: err.message }), { status: 500 });
    }
}