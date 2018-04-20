$(document).ready(function() {
  $('#getListBtn').click(function() {
    $.ajax({
      method: 'GET',
      url: '/list'
    }).done(function(data) {
      $('#container').html(data);
    });
  });

  $('#addItemBtn').click(function() {
    $.ajax({
      method: 'GET',
      url: '/edit/0'
    }).done(function(data) {
      $('#container').html(data);
    });
  });

  $(document).on('click', '#listAccordion .editItemBtn', function(e) {
    var id = e.target.getAttribute('data-item-id');
    var url = '/edit/' + id;

    $.ajax({
      method: 'GET',
      url: url
    }).done(function(data) {
      $('#container').html(data);
      var el = $('#itemForm input[type=radio][name=type][checked]');
      if (el.length) checkHiddenInputs(el);
    });
  });

  $(document).on('submit', '#itemForm', function(e) {
    e.preventDefault();
    var url = e.target.getAttribute('action') || '/save';
    var formData = $('#itemForm :visible').serializeArray();

    $.ajax({
      method: 'POST',
      url: url,
      data: formData
    }).done(function(data) {
      $('#container').html(data);
    });
  });

  $(document).on('click', '#itemForm #deleteItemBtn', function() {
    var url = '/delete';
    var id = $('#itemForm #id').val();

    $.ajax({
      method: 'POST',
      url: url,
      data: { id: id }
    }).done(function(data) {
      $('#container').html(data);
    });
  });

  function checkHiddenInputs(el) {
    var showType = el.val();
    var hideType = showType === 'legal' ? 'natural' : 'legal';

    $('#' + showType + 'TypeFields')
      .removeAttr('hidden')
      .find('input[data-required]')
      .each(function() {
        var dataRequired = el.attr('data-required');
        el.removeAttr('data-required').attr('required', dataRequired);
      });

    $('#' + hideType + 'TypeFields')
      .attr('hidden', true)
      .find('input[required]')
      .each(function() {
        var required = el.attr('required');
        el.removeAttr('required').attr('data-required', required);
      });
  }

  $(document).on(
    'change',
    '#itemForm input[type=radio][name=type]',
    function() {
      checkHiddenInputs($(this));
    }
  );
});
