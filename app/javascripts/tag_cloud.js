function tagCloud(q, limit) {
  var counts = db.eval(
    function(q){
      var counts = {};
      db.questions.find(q).limit(500).forEach(
        function(p){
          if ( p.tags ){
            for ( var i=0; i<p.tags.length; i++ ){
              var name = p.tags[i];
              counts[name] = 1 + ( counts[name] || 0 );
            }
          }
        }
      );
      return counts;
    },
    q
  );

  // maybe sort to by nice
  var sorted = [];
  for ( var tag in counts ){
    sorted.push( { name : tag , count : counts[tag] } )
  }

  return sorted.sort(
    function(l,r){
      return r.count - l.count;
    }
  ).slice(0,limit||30);
}
