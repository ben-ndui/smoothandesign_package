## 1.6.3

* `MessagingBloc.OpenConversationEvent` : `_onOpenConversation` n'avait aucun
  garde-fou (contrairement a `_onLoadConversations`, deja protege par son
  verrou `_currentUserId`/etat) et annulait/reassignait
  `_messagesSubscription`/`_conversationSubscription` sans jamais verifier
  s'il etait deja en cours pour le meme event. Deux dispatches rapproches
  (double tap sur une conversation) pouvaient laisser un flux Firestore actif
  et invisible. Fix : `transformer: restartable()` (nouveau, `bloc_concurrency`).
  Meme defaut, memes effets, que celui corrige le 29/10/2026 dans le
  `FavoriteBloc` d'UZME. `LoadConversationsEvent` recoit le meme transformer
  par coherence, meme si son garde existant le protegeait deja dans les cas
  testes.

## 1.6.2

* `AppSnackBar` suit désormais le thème de l'app appelante au lieu d'un gris
  ardoise codé en dur (`#1E293B`) : fond `colorScheme.surfaceContainerHigh`,
  texte `colorScheme.onSurface`. Le type `info` reprend `colorScheme.primary`
  au lieu d'un bleu fixe. success/error/warning gardent leur sémantique
  universelle (vert/rouge/orange), inchangée. Relevé sur UZME, 29/10/2026 :
  le snackbar ne suivait pas la DA en thème sombre. `getTypeConfig` prend
  maintenant un `ThemeData` en second paramètre (signature publique changée,
  aucun appelant de ce repo ne l'utilisait directement en dehors du fichier).

## 1.5.1

* Google Play Billing 8 : `in_app_purchase` ^3.2.0 → ^3.3.0
  (`in_app_purchase_android` 0.5.x embarque la Play Billing Library 8.0.0,
  exigence Google Play au 31/08/2026). Aucun impact API : le package
  n'utilisait pas `queryPurchaseHistory` (supprimé en 0.5.0).

## 0.0.1

* TODO: Describe initial release.
