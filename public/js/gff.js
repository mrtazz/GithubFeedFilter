$(document).ready(function(){

  $("#signinform").submit(function(ev)
    {
      ev.preventDefault();

      var $form = $( this ),
        user = $form.find( 'input[name="username"]' ).val(),
        pw = $form.find( 'input[name="password"]' ).val();

      var jqxhr = $.post("/sign_in", {"name": user, "password": pw}, function() {
          })
          .success(function()
              {
                nextweek = new Date((new Date()).getTime() + (1000 * 60 * 60 * 24 * 7));
                document.cookie =
                  'github_token='+user+':'+pw+'; expires='+nextweek.toUTCString()+'; path=/';
              })

          jqxhr.complete(function(){ window.location.href = "/"; });

    });

    $("#logout").click(function()
        {
          document.cookie = "github_token=; expires="+(new Date(-1).toUTCString())+"; path=/";
        });

    $('.check').change(function() {

      var repo = $(this).parents("p").children("span.reponame").children("a").html();
      var e = $(this).attr("name");
      var checked = $(this).is(":checked");

      $.ajax({
        type: "PUT",
        url: "/settings",
        data: {"repo": repo, "event": e, "checked": checked},
        success: function(msg){
        }
      });


    });



});
