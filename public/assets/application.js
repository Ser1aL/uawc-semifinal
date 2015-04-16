$(document).ready(function(){

  $('.main-tab-panel a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
  });

  $('.main-tab-panel li a.active').tab('show');

  $("#inputFile").fileinput({'showPreview':false});
  $('.tags_input').tagsinput()

});