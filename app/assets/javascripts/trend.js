/**
 * Produces trend graphs for problem occurrences
 */
$(document).ready(function(){
  $('canvas.bar-chart').each(function(){
    var canvas = $(this);
    var ctx = canvas.get(0).getContext("2d");

    var data = {
      labels: canvas.data('labels'),
      datasets : [
        {
          data : canvas.data('notice-count')
        },
      ]
    }

    var origHeight = canvas.attr('height');
    var origWidth = canvas.attr('width');

    chart = new Chart(ctx);

    // hack to allow offscreen rendering using preset height/width
    if (typeof origHeight !== 'undefined' && typeof origWidth !== 'undefined') {
      chart.ctx.canvas.height = chart.height = origHeight;
      chart.ctx.canvas.width = chart.width = origWidth;
      Chart.helpers.retinaScale(chart);
    }

    chart.Bar(data, {
      scaleShowLabels: canvas.data('show-labels'),
      scaleOverride: true,
      scaleSteps: canvas.data('scale-steps'),
      scaleStepWidth: 1,
      scaleStartValue: 0,
      animation: false,
      scaleShowGridLines: false,
      barValueSpacing: 1
    });
  });
});
