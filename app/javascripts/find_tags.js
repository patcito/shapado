function findTags(regex, limit) {
  var tags = db.eval(
    function(regex){
      var tags = [];
      db.questions.find({}, {"tags":1}).limit(500).forEach(
        function(p){
          if ( p.tags ){
            for ( var i=0; i<p.tags.length; i++ ){
              var name = p.tags[i];
              if(name.match(regex) != null && tags.indexOf(name) == -1)
                tags.push(name);
            }
          }
        }
      );
      return tags;
    },
    regex
  );

  return tags.slice(0,limit||30);
}
