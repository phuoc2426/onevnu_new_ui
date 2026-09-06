import 'package:vnu_core/common/log.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Cấu hình hiển thị + diagnostic dùng chung cho WebView ONEVNU.
///
/// Nguyên tắc:
/// - Không hard-code width theo model điện thoại.
/// - Không scale/zoom toàn trang để che lỗi responsive.
/// - Android bật wide viewport và text zoom 100%.
/// - Chuẩn hóa viewport + căn giữa các root container bị lệch.
/// - Chỉ log geometry/host/path, KHÔNG log query/cookie/token/nội dung form.
class VcoreWebViewSupport {
  const VcoreWebViewSupport._();

  static String safePage(String? rawUrl) {
    final Uri? uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (uri == null) return 'unknown';

    final String scheme = uri.scheme.isEmpty ? '' : '${uri.scheme}://';
    final String host = uri.host;
    final String path = uri.path.isEmpty ? '/' : uri.path;
    return '$scheme$host$path';
  }

  static Future<void> configurePlatform(
    WebViewController controller, {
    String traceTag = 'COMMON',
  }) async {
    try {
      final Object platform = controller.platform;
      if (platform is AndroidWebViewController) {
        await platform.setUseWideViewPort(true);
        await platform.setTextZoom(100);
        dlog(
          '[WEBVIEW_DIAG][$traceTag][ANDROID_CONFIG] '
          'useWideViewPort=true textZoom=100',
        );
        return;
      }

      dlog(
        '[WEBVIEW_DIAG][$traceTag][PLATFORM_CONFIG] '
        'platform=${platform.runtimeType}',
      );
    } catch (error, stackTrace) {
      dlog(
        '[WEBVIEW_DIAG][$traceTag][PLATFORM_CONFIG_ERROR] '
        'type=${error.runtimeType} message=$error',
      );
      dlog(_compactStack(stackTrace));
      // Không để cấu hình hiển thị chặn việc đăng nhập/mở WebView.
    }
  }

  /// Chuẩn hóa responsive sau khi trang load.
  ///
  /// Ngoài lần chạy đầu, JS cài một MutationObserver + resize listener rất nhẹ
  /// để trang SPA/hydration thay DOM sau onPageFinished vẫn được căn lại.
  static Future<void> normalizeResponsiveLayout(
    WebViewController controller, {
    String traceTag = 'COMMON',
  }) async {
    try {
      await traceLayout(controller, traceTag: traceTag, phase: 'BEFORE_NORMALIZE');
      await controller.runJavaScript(r'''
(() => {
  const doc = document;
  if (!doc) return;

  const head = doc.head || doc.getElementsByTagName('head')[0];
  if (!head) return;

  let viewport = doc.querySelector('meta[name="viewport"]');
  if (!viewport) {
    viewport = doc.createElement('meta');
    viewport.setAttribute('name', 'viewport');
    head.appendChild(viewport);
  }

  viewport.setAttribute(
    'content',
    'width=device-width, initial-scale=1.0, viewport-fit=cover'
  );

  const normalize = () => {
    const html = doc.documentElement;
    const body = doc.body;
    if (!html || !body) return;

    html.style.setProperty('width', '100%', 'important');
    html.style.setProperty('max-width', '100%', 'important');
    html.style.setProperty('min-width', '0', 'important');
    html.style.setProperty('margin-left', 'auto', 'important');
    html.style.setProperty('margin-right', 'auto', 'important');
    html.style.setProperty('overflow-x', 'hidden', 'important');
    html.style.setProperty('box-sizing', 'border-box', 'important');

    body.style.setProperty('width', '100%', 'important');
    body.style.setProperty('max-width', '100%', 'important');
    body.style.setProperty('min-width', '0', 'important');
    body.style.setProperty('margin-left', 'auto', 'important');
    body.style.setProperty('margin-right', 'auto', 'important');
    body.style.setProperty('overflow-x', 'hidden', 'important');
    body.style.setProperty('box-sizing', 'border-box', 'important');

    const viewportWidth = Math.max(
      1,
      html.clientWidth || 0,
      window.innerWidth || 0
    );

    // Chỉ can thiệp root container trực tiếp của BODY. Không sửa component
    // con, input, card... nên responsive CSS của website vẫn là nguồn chính.
    Array.from(body.children).forEach((element) => {
      if (!(element instanceof HTMLElement)) return;

      const style = window.getComputedStyle(element);
      if (!['block', 'flex', 'grid', 'flow-root'].includes(style.display)) {
        return;
      }
      if (['absolute', 'fixed', 'sticky'].includes(style.position)) {
        return;
      }

      const rect = element.getBoundingClientRect();
      if (!Number.isFinite(rect.width) || rect.width <= 0) return;
      if (rect.width > viewportWidth + 2) return;

      const leftGap = rect.left;
      const rightGap = viewportWidth - rect.right;
      const asymmetric = Math.abs(leftGap - rightGap) > 2;
      if (!asymmetric) return;

      element.style.setProperty('margin-left', 'auto', 'important');
      element.style.setProperty('margin-right', 'auto', 'important');

      // Một số theme dùng position:relative + left để dịch root container.
      if (style.position === 'relative') {
        element.style.setProperty('left', 'auto', 'important');
        element.style.setProperty('right', 'auto', 'important');
      }
    });


    // Fallback cho trường hợp BODY/root đã full-width nhưng card/layout chính
    // ở bên trong vẫn lệch. Chỉ chọn 1 container "dominant" có diện tích lớn,
    // rộng 55-99% viewport và cao đáng kể; không đụng input/button/text nhỏ.
    const viewportHeight = Math.max(1, window.innerHeight || 0);
    let dominant = null;
    let dominantScore = -1;

    Array.from(body.querySelectorAll('*')).slice(0, 500).forEach((element) => {
      if (!(element instanceof HTMLElement)) return;

      const style = window.getComputedStyle(element);
      if (!['block', 'flex', 'grid', 'flow-root'].includes(style.display)) {
        return;
      }
      if (['absolute', 'fixed', 'sticky'].includes(style.position)) {
        return;
      }

      const rect = element.getBoundingClientRect();
      if (!Number.isFinite(rect.width) || !Number.isFinite(rect.height)) return;
      if (rect.width < viewportWidth * 0.55) return;
      if (rect.width >= viewportWidth - 2) return;
      if (rect.height < Math.min(220, viewportHeight * 0.35)) return;

      const leftGap = rect.left;
      const rightGap = viewportWidth - rect.right;
      if (Math.abs(leftGap - rightGap) <= 3) return;

      const score = rect.width * rect.height;
      if (score > dominantScore) {
        dominant = element;
        dominantScore = score;
      }
    });

    if (dominant) {
      const dominantStyle = window.getComputedStyle(dominant);
      dominant.style.setProperty('margin-left', 'auto', 'important');
      dominant.style.setProperty('margin-right', 'auto', 'important');
      if (dominantStyle.position === 'relative') {
        dominant.style.setProperty('left', 'auto', 'important');
        dominant.style.setProperty('right', 'auto', 'important');
      }
      dominant.setAttribute('data-onevnu-centered', 'true');
    }

    // Keycloak/VNU IDP currently renders .login-pf-page with a measurable
    // horizontal offset on narrow Android WebViews (example: viewport=360,
    // rect=16..366 => centerDelta=+11). Margin/left normalization above cannot
    // fix a grid-placement offset, so compensate by the ACTUAL measured delta.
    // No device-width or -11px constant is used.
    const centerMeasuredElement = (element, source) => {
      if (!(element instanceof HTMLElement)) return;

      const owned =
        element.getAttribute('data-onevnu-dynamic-centered') === 'true';
      const style = window.getComputedStyle(element);

      // Never overwrite a website transform unless it is a transform we
      // previously installed ourselves.
      if (!owned && style.transform && style.transform !== 'none') return;

      const rect = element.getBoundingClientRect();
      if (!Number.isFinite(rect.width) || rect.width <= 0) return;
      if (rect.width > viewportWidth + 2) return;

      const centerDelta =
        ((rect.left + rect.right) / 2) - (viewportWidth / 2);

      element.setAttribute('data-onevnu-centered', 'true');
      element.setAttribute('data-onevnu-center-source', source);

      if (Math.abs(centerDelta) <= 0.75) return;

      const previousShift = Number.parseFloat(
        element.getAttribute('data-onevnu-center-shift') || '0'
      );
      const safePreviousShift = Number.isFinite(previousShift)
        ? previousShift
        : 0;
      const nextShift = safePreviousShift - centerDelta;

      // Avoid MutationObserver churn for sub-pixel changes.
      if (Math.abs(nextShift - safePreviousShift) <= 0.25) return;

      element.style.setProperty(
        'transform',
        `translate3d(${nextShift}px, 0, 0)`,
        'important'
      );
      element.style.setProperty('transform-origin', 'center center', 'important');
      element.setAttribute('data-onevnu-dynamic-centered', 'true');
      element.setAttribute('data-onevnu-center-shift', String(nextShift));
    };

    // Prefer the known Keycloak page root. Centering the parent moves the
    // entire form/card/header together and avoids touching inputs/buttons.
    const idpPage = body.querySelector('.login-pf-page');
    if (idpPage) {
      centerMeasuredElement(idpPage, 'login-pf-page');
    }
  };

  normalize();
  window.setTimeout(normalize, 120);
  window.setTimeout(normalize, 420);

  if (window.__onevnuCenterObserver) {
    try { window.__onevnuCenterObserver.disconnect(); } catch (_) {}
  }

  let scheduled = false;
  const scheduleNormalize = () => {
    if (scheduled) return;
    scheduled = true;
    window.requestAnimationFrame(() => {
      scheduled = false;
      normalize();
    });
  };

  if (doc.body && window.MutationObserver) {
    const observer = new MutationObserver(scheduleNormalize);
    observer.observe(doc.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class', 'style']
    });
    window.__onevnuCenterObserver = observer;
  }

  window.removeEventListener('resize', window.__onevnuCenterResizeHandler || (() => {}));
  window.__onevnuCenterResizeHandler = scheduleNormalize;
  window.addEventListener('resize', scheduleNormalize, { passive: true });

  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', scheduleNormalize, { passive: true });
  }
})();
''');

      await traceLayout(controller, traceTag: traceTag, phase: 'AFTER_NORMALIZE');
      await Future<void>.delayed(const Duration(milliseconds: 480));
      await traceLayout(controller, traceTag: traceTag, phase: 'SETTLED');
    } catch (error, stackTrace) {
      dlog(
        '[WEBVIEW_DIAG][$traceTag][NORMALIZE_ERROR] '
        'type=${error.runtimeType} message=$error',
      );
      dlog(_compactStack(stackTrace));
      // Không để JS normalize làm hỏng luồng WebView.
    }
  }

  /// Log geometry đủ để biết WebView có viewport sai, overflow ngang,
  /// body/root/card bị lệch hoặc có transform/margin bất thường.
  /// Không đọc text/value/input/cookie/localStorage/sessionStorage.
  static Future<void> traceLayout(
    WebViewController controller, {
    String traceTag = 'COMMON',
    String phase = 'MANUAL',
  }) async {
    try {
      final String? currentUrl = await controller.currentUrl();
      final Object metrics = await controller.runJavaScriptReturningResult(r'''
(() => {
  const html = document.documentElement;
  const body = document.body;
  const vv = window.visualViewport;
  const viewportWidth = Math.max(1, html ? html.clientWidth : window.innerWidth);
  const viewportHeight = Math.max(1, html ? html.clientHeight : window.innerHeight);

  const round = (n) => Number.isFinite(n) ? Math.round(n * 100) / 100 : null;
  const rectOf = (el) => {
    if (!el || !el.getBoundingClientRect) return null;
    const rect = el.getBoundingClientRect();
    return {
      left: round(rect.left),
      top: round(rect.top),
      right: round(rect.right),
      bottom: round(rect.bottom),
      width: round(rect.width),
      height: round(rect.height),
      centerDelta: round(((rect.left + rect.right) / 2) - (viewportWidth / 2))
    };
  };

  const styleOf = (el) => {
    if (!el) return null;
    const style = window.getComputedStyle(el);
    return {
      display: style.display,
      position: style.position,
      width: style.width,
      maxWidth: style.maxWidth,
      marginLeft: style.marginLeft,
      marginRight: style.marginRight,
      paddingLeft: style.paddingLeft,
      paddingRight: style.paddingRight,
      left: style.left,
      right: style.right,
      transform: style.transform,
      overflowX: style.overflowX,
      boxSizing: style.boxSizing,
      direction: style.direction
    };
  };

  const describe = (el) => ({
    tag: el.tagName,
    id: el.id || '',
    className: typeof el.className === 'string'
      ? el.className.slice(0, 140)
      : '',
    rect: rectOf(el),
    style: styleOf(el),
    onevnuCenterSource: el.getAttribute('data-onevnu-center-source'),
    onevnuCenterShift: el.getAttribute('data-onevnu-center-shift')
  });

  const centered = document.querySelector('[data-onevnu-centered="true"]');
  const directChildren = body
    ? Array.from(body.children).slice(0, 12).map(describe)
    : [];

  const candidates = [];
  if (body) {
    Array.from(body.querySelectorAll('*')).slice(0, 700).forEach((el) => {
      if (!(el instanceof HTMLElement)) return;
      const style = window.getComputedStyle(el);
      if (!['block', 'flex', 'grid', 'flow-root'].includes(style.display)) return;
      if (['fixed'].includes(style.position)) return;
      const rect = el.getBoundingClientRect();
      if (!Number.isFinite(rect.width) || !Number.isFinite(rect.height)) return;
      if (rect.width < 120 || rect.height < 100) return;
      if (rect.width > viewportWidth * 1.4) return;
      const centerDelta = ((rect.left + rect.right) / 2) - (viewportWidth / 2);
      if (Math.abs(centerDelta) < 2 && rect.right <= viewportWidth + 2) return;
      candidates.push({
        score: Math.abs(centerDelta) * Math.min(rect.height, viewportHeight),
        element: el
      });
    });
  }
  candidates.sort((a, b) => b.score - a.score);

  return JSON.stringify({
    window: {
      innerWidth: window.innerWidth,
      innerHeight: window.innerHeight,
      outerWidth: window.outerWidth,
      outerHeight: window.outerHeight,
      scrollX: window.scrollX,
      scrollY: window.scrollY,
      devicePixelRatio: window.devicePixelRatio,
      screenWidth: window.screen ? window.screen.width : null,
      screenAvailWidth: window.screen ? window.screen.availWidth : null
    },
    viewport: {
      clientWidth: html ? html.clientWidth : null,
      clientHeight: html ? html.clientHeight : null,
      scrollWidth: html ? html.scrollWidth : null,
      scrollHeight: html ? html.scrollHeight : null,
      visualWidth: vv ? vv.width : null,
      visualHeight: vv ? vv.height : null,
      visualScale: vv ? vv.scale : null,
      visualOffsetLeft: vv ? vv.offsetLeft : null,
      visualOffsetTop: vv ? vv.offsetTop : null
    },
    html: { rect: rectOf(html), style: styleOf(html) },
    body: {
      rect: rectOf(body),
      style: styleOf(body),
      scrollWidth: body ? body.scrollWidth : null,
      scrollHeight: body ? body.scrollHeight : null
    },
    activeElementTag: document.activeElement ? document.activeElement.tagName : null,
    centeredCandidate: centered ? describe(centered) : null,
    directChildren,
    asymmetricCandidates: candidates.slice(0, 12).map((x) => describe(x.element))
  });
})()
''');

      dlog(
        '[WEBVIEW_DIAG][$traceTag][$phase] '
        'page=${safePage(currentUrl)} metrics=$metrics',
        wrapWidth: 2000,
      );
    } catch (error, stackTrace) {
      dlog(
        '[WEBVIEW_DIAG][$traceTag][TRACE_ERROR] '
        'phase=$phase type=${error.runtimeType} message=$error',
      );
      dlog(_compactStack(stackTrace));
    }
  }

  static String _compactStack(StackTrace stackTrace) {
    return stackTrace
        .toString()
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .take(8)
        .join(' | ');
  }
}
