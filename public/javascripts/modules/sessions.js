$(function() {
  $('#nojsopenid').remove();

  var oid = $('#openid');

  if(oid.length == 0)
    return;

  $('#openid').openid({
    txt: {
      label: "Enter your <b>{provider}</b> {username}",
      username: 'login',
      title: 'Select your account provider.',
      sign: 'Sign-in'
    }
  });
});

