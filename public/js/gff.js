$(document).ready(function(){

  $("#signinform").submit(function(ev)
    {
      ev.preventDefault();

      var $form = $( this ),
        user = $form.find( 'input[name="username"]' ).val(),
        pw = $form.find( 'input[name="password"]' ).val();


      $.post("/sign_in", {"name": user, "password": pw}, function(data)
        {
          console.log("POST DONE");
          nextweek = new Date((new Date()).getTime() + (1000 * 60 * 60 * 24 * 7));
          document.cookie =
            'github_token='+user+':'+pw+'; expires='+nextweek.toUTCString()+'; path=/';

          window.location.href = "http://localhost:4567/";
        });


    });

});
