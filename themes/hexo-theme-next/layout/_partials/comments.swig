{% if page.comments %}
  <div class="comments" id="comments">
    {% if (theme.duoshuo and theme.duoshuo.shortname) or theme.duoshuo_shortname %}
      <div class="ds-thread" data-thread-key="{{ page.path }}"
           data-title="{{ page.title }}" data-url="{{ page.permalink }}">
      </div>
    {% elseif theme.facebook_sdk.enable and theme.facebook_comments_plugin.enable %}
      <div class="fb-comments"
           data-href="{{ page.permalink }}"
           data-numposts="{{ theme.facebook_comments_plugin.num_of_posts }}"
           data-width="{{ theme.facebook_comments_plugin.width }}"
           data-colorscheme="{{ theme.facebook_comments_plugin.scheme }}">
      </div>
    {% elseif theme.vkontakte_api.enable and theme.vkontakte_api.comments %}
      <div id="vk_comments"></div>
    {% elseif theme.disqus_shortname %}
      <div id="disqus_thread">
        <noscript>
          Please enable JavaScript to view the
          <a href="//disqus.com/?ref_noscript">comments powered by Disqus.</a>
        </noscript>
      </div>
    {% elseif theme.hypercomments_id %}
      <div id="hypercomments_widget"></div>
    {% elseif theme.gentie_productKey %}
      <div id="cloud-tie-wrapper" class="cloud-tie-wrapper"></div>
    {% elseif theme.youyan_uid %}
      <div id="uyan_frame"></div>
    {% elseif theme.livere_uid %}
      <div id="lv-container" data-id="city" data-uid="{{ theme.livere_uid }}"></div>
    {% elseif theme.changyan.appid and theme.changyan.appkey %}
      <div id="SOHUCS"></div>
    {% elseif theme.comment_js.enable %}
        <div id="comment-thread"></div>
        <script type="text/javascript">
          var opt = {
              type: "github",
              user: "pylixm",
              repo: "pylixm_hexo",
              no_comment: "No comments yet. Press the button and go to comment now!",
              go_to_comment: "Go to comment",
              issue_title: "{{ page.title }}",
              issue_id: "{{ page.issue_id }}",
              btn_class: "btn",
              comments_target: "#comment-thread",
              loading_target: "#loading-spin",
              client_id: "3bfeabded9187bfed657",
              client_secret: "9a8b545a31b1467b676e45a8cf990dad94c5c06a"
          };
          getComments(opt);
        </script>
    {% endif %}
  </div>
{% endif %}
