class CustomHtml
  include MongoMapper::EmbeddedDocument

  key :_id, String
  key :top_bar, String, :default => "[[faq|FAQ]]"

  key :question_prompt, Hash, :default => {"en" => "what's your question? be descriptive.",
                                           "es" => "¿cual es tu pregunta? por favor se descriptivo.",
                                           "fr" => "quelle est votre question? soyez descriptif.",
                                           "pt" => "qual é a sua pergunta? seja descritivo."}
  key :question_help, Hash, :default => {
"en" => "Provide as much details as possible so that it will have more
chance to be answered instead of being endlessly discussed.
Try to be clear and simple.",
"es" => "Sobre que es tu pregunta?
provee tantos detalles como puedas para tener más suerte
de conseguir una respuesta y no una discusion sin fin.
intenta ser claro y simple",
"fr" => "Sur quoi porte votre question?
Donnez autants de détails que possible afin d'avoir plus de chance
d'obtenir une réponse et non une discussion sans fin. Éssayer d'être clair et simple.",
"pt" => ""}

  key :head, Hash, :default => {}
  key :footer, String
  key :head_tag, String
end
